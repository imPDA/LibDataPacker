#!/usr/bin/env python3
"""
Pre-commit hook: Check if any dependency in manifest has a newer version on ESOUI.
Also raises an error if a dependency does not specify a version (e.g., missing '>=NN').
Caches the API response for 24 hours.
"""

import json
import re
import sys
import time
from pathlib import Path
from urllib.request import urlopen, Request
from urllib.error import URLError

# ========== CONFIGURATION ==========
API_URL = "https://api.mmoui.com/v4/game/ESO/filelist.json"
CACHE_FILE = Path.home() / ".cache" / "mmoui_deps.json"
CACHE_TTL_SECONDS = 24 * 60 * 60   # 1 day
FAIL_ON_OUTDATED = False           # Block commit if any dependency is outdated
FAIL_ON_MISSING_VERSION = True     # Block commit if any dependency lacks a version
# ===================================

def find_manifest_file():
    """Locate the dependency manifest (.addon or <dirname>.txt) in cwd."""
    cwd = Path.cwd()

    # 1. Look for any .addon file
    addon_files = list(cwd.glob("*.addon"))
    if len(addon_files) == 1:
        return addon_files[0]
    elif len(addon_files) > 1:
        print("ERROR: Multiple .addon files found. Please keep only one.")
        sys.exit(1)

    # 2. Look for <dirname>.txt
    txt_file = cwd / f"{cwd.name}.txt"
    if txt_file.is_file():
        return txt_file

    print("ERROR: No manifest found. Expected a .addon file or a .txt file named after the folder.")
    sys.exit(1)

def parse_dependencies(manifest_path):
    """
    Extract dependencies from #DependsOn: line.
    Dependencies are separated by SPACE (not comma).
    Returns:
        valid_deps: list of (name, version_int)
        missing_version: list of names that had no '>=NN'
    """
    valid_deps = []
    missing_version = []
    with open(manifest_path, 'r', encoding='utf-8') as f:
        for line in f:
            if line.startswith("#DependsOn:"):
                parts = line.split(":", 1)
                if len(parts) < 2:
                    continue
                dep_string = parts[1].strip()
                # Split by whitespace (space, tab, newline)
                for entry in dep_string.split():
                    entry = entry.strip()
                    if not entry:
                        continue
                    # Expect format "LibName>=42"
                    match = re.match(r'^(.+?)>=(\d+)$', entry)
                    if match:
                        name = match.group(1).strip()
                        ver = int(match.group(2))
                        valid_deps.append((name, ver))
                    else:
                        # No version specified (or malformed)
                        missing_version.append(entry)
    return valid_deps, missing_version

def fetch_latest_versions():
    """Download JSON from API, respect cache TTL."""
    CACHE_FILE.parent.mkdir(parents=True, exist_ok=True)

    if CACHE_FILE.exists():
        age = time.time() - CACHE_FILE.stat().st_mtime
        if age < CACHE_TTL_SECONDS:
            print("Using cached library data (less than 24h old).")
            with open(CACHE_FILE, 'r', encoding='utf-8') as f:
                return json.load(f)

    print("Fetching latest library versions from ESOUI...")
    try:
        req = Request(API_URL, headers={'User-Agent': 'AddonDev-Hook/1.0'})
        with urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode('utf-8'))
            with open(CACHE_FILE, 'w', encoding='utf-8') as f:
                json.dump(data, f)
            return data
    except URLError as e:
        print(f"ERROR: Cannot fetch API data: {e}")
        if CACHE_FILE.exists():
            print("Using stale cache as fallback.")
            with open(CACHE_FILE, 'r', encoding='utf-8') as f:
                return json.load(f)
        else:
            print("No cache available. Aborting check.")
            sys.exit(1)

def build_version_map(api_data):
    """Create dict {title: version_int} from API response."""
    version_map = {}
    for entry in api_data:
        title = entry.get("title")
        ver_str = entry.get("version")
        if title and ver_str:
            try:
                version_map[title] = int(ver_str)
            except ValueError:
                version_map[title] = ver_str
    return version_map

def main():
    manifest = find_manifest_file()
    print(f"Using manifest: {manifest}")
    valid_deps, missing_version = parse_dependencies(manifest)

    # Error: dependencies without version
    if missing_version and FAIL_ON_MISSING_VERSION:
        print("\n" + "="*60)
        print("❌ ERROR: Dependencies without version specification found:")
        for dep in missing_version:
            print(f"  {dep}")
        print("\nEach dependency must include '>=<version>' (e.g., LibAsync>=43).")
        print("="*60 + "\n")
        sys.exit(1)
    elif missing_version:
        print("\n⚠️  WARNING: Dependencies without version (ignored because FAIL_ON_MISSING_VERSION=False):")
        for dep in missing_version:
            print(f"  {dep}")

    if not valid_deps:
        print("No valid dependencies with version found. Nothing to check.")
        sys.exit(0)

    api_data = fetch_latest_versions()
    latest = build_version_map(api_data)

    outdated = []
    for name, required_ver in valid_deps:
        latest_ver = latest.get(name)
        if latest_ver is None:
            print(f"⚠️  Library '{name}' not found in ESOUI database. Skipping.")
            continue

        try:
            if int(latest_ver) > required_ver:
                outdated.append((name, required_ver, latest_ver))
        except (TypeError, ValueError):
            if str(latest_ver) > str(required_ver):
                outdated.append((name, required_ver, latest_ver))

    if outdated:
        print("\n" + "="*60)
        print("⚠️  OUTDATED DEPENDENCIES DETECTED")
        for name, required, latest_ver in outdated:
            print(f"  {name}: required >= {required}, latest is {latest_ver}")
        print("\nConsider updating your #DependsOn: line.")
        print("="*60 + "\n")
        if FAIL_ON_OUTDATED:
            print("Commit blocked (FAIL_ON_OUTDATED = True).")
            sys.exit(1)
        else:
            print("Commit allowed, but please update dependencies soon.")
    else:
        print("✅ All dependencies are up to date (or no newer version found).")

    sys.exit(0)


if __name__ == "__main__":
    main()
