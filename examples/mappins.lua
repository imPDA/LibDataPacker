local LDP = LibDataPacker
local Field = LDP.Field

LDP.examples = LDP.examples or {}
LDP.examples.MapPins = {}

local example = LDP.examples.MapPins

local SCHEMA = Field.VLArray(nil,
    1023,
    Field.Table(nil, {
        Field.Number('x', 11, 3),
        Field.Number('y', 11, 3),
        Field.Number('t', 3),
    }, true)
)

local function run()
    -- public FishingNodes_key and DecodeData
    -- GLOBAL_FISHING_NODES_KEY = FishingNodes_key
    -- GLOBAL_DECODE_DATA = DecodeData

    local grand = {}
    GLOBAL_GRAND_TABLE = grand

    local t0

    for mapId in pairs(GLOBAL_FISHING_NODES_KEY) do
        grand[mapId] = {}
        -- ImpData1[mapId] = {}

        t0 = GetGameTimeSeconds()
        local data = GLOBAL_DECODE_DATA('FishingNodes', mapId)
        grand[mapId].decode = (GetGameTimeSeconds() - t0) * 1000
        grand[mapId] = data
        -- ImpData1[mapId] = data

        t0 = GetGameTimeSeconds()
        local packed = LDP.Pack(data, SCHEMA)
        grand[mapId].packing = (GetGameTimeSeconds() - t0) * 1000
        grand[mapId].packed = packed
        -- ImpData1[mapId] = packed

        grand[mapId].len = #grand[mapId].packed
        grand[mapId].originalLen = GLOBAL_FISHING_NODES_KEY[mapId][2] - GLOBAL_FISHING_NODES_KEY[mapId][1]
        grand[mapId].ratio = grand[mapId].len / grand[mapId].originalLen

        t0 = GetGameTimeSeconds()
        local unpacked = LDP.Unpack(packed, SCHEMA)
        grand[mapId].unpacking = (GetGameTimeSeconds() - t0) * 1000
        grand[mapId].unpacked = unpacked

        -- grand[mapId].equal =
    end

    Zgoo:Main(nil, 0, grand)
end

-- Deep comparison of two Lua values (tables, primitives, functions, etc.)
-- @param a First value
-- @param b Second value
-- @param seen Optional table for cycle detection (used internally)
-- @return boolean true if a and b are deeply equal
-- local function deep_equal(a, b, seen)
--     -- Same reference or identical primitives
--     if a == b then
--         return true
--     end

--     -- If only one is nil
--     if a == nil or b == nil then
--         return false
--     end

--     local type_a = type(a)
--     local type_b = type(b)

--     -- Different types -> not equal
--     if type_a ~= type_b then
--         return false
--     end

--     -- For non-tables, compare directly (numbers, strings, booleans, functions)
--     if type_a ~= "table" then
--         return a == b
--     end

--     -- Cycle detection: use a list of visited table pairs
--     seen = seen or {}
--     for i = 1, #seen do
--         if seen[i][1] == a and seen[i][2] == b then
--             return true  -- Already visited, assume equal to avoid infinite recursion
--         end
--     end
--     seen[#seen + 1] = { a, b }

--     -- Compare table sizes (number of keys) quickly via next
--     local count_a, count_b = 0, 0
--     for _ in pairs(a) do count_a = count_a + 1 end
--     for _ in pairs(b) do count_b = count_b + 1 end
--     if count_a ~= count_b then
--         return false
--     end

--     -- Compare each key-value pair in a with b
--     for k, v in pairs(a) do
--         -- Check that key exists in b
--         local b_val = b[k]
--         if not deep_equal(v, b_val, seen) then
--             return false
--         end
--     end

--     -- Optionally compare metatables (uncomment if needed)
--     -- if getmetatable(a) ~= getmetatable(b) then
--     --     return false
--     -- end

--     return true
-- end

-- local function checkData()
--     local grand = {}

--     for mapId, packedMapData in pairs(PACKED_FISHING_HOLES) do
--         -- ImpData1[mapId] = {}

--         local data = GLOBAL_DECODE_DATA('FishingNodes', mapId)
--         local unpacked = LDP.Unpack(packedMapData, SCHEMA, LDP.Base.Primitive)

--         df('Map %d equal: %s', mapId, tostring(deep_equal(data, unpacked)))

--         grand[mapId] = {
--             unpacked = unpacked,
--             original = data,
--         }
--     end

--     Zgoo:Main(nil, 0, grand)
-- end

example.run = run
-- example.checkData = checkData
