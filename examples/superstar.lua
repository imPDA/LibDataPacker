local Log = LibDataPacker_Logger()

-- ----------------------------------------------------------------------------

--- https://stackoverflow.com/questions/20325332/how-to-check-if-two-tablesobjects-have-the-same-value-in-lua
--- @param o1 any|table First object to compare
--- @param o2 any|table Second object to compare
--- @param ignore_mt boolean True to ignore metatables (a recursive function to tests tables inside tables)
local function equals(o1, o2, ignore_mt)
    if o1 == o2 then return true end
    local o1Type = type(o1)
    local o2Type = type(o2)
    if o1Type ~= o2Type then return false end
    if o1Type ~= 'table' then return false end

    if not ignore_mt then
        local mt1 = getmetatable(o1)
        if mt1 and mt1.__eq then
            --compare using built in method
            return o1 == o2
        end
    end

    local keySet = {}

    for key1, value1 in pairs(o1) do
        local value2 = o2[key1]
        if value2 == nil or equals(value1, value2, ignore_mt) == false then
            return false
        end
        keySet[key1] = true
    end

    for key2, _ in pairs(o2) do
        if not keySet[key2] then return false end
    end
    return true
end

-- ----------------------------------------------------------------------------

local LDP = LibDataPacker
LDP.examples = LDP.examples or {}
LDP.examples.SuperStar = {}

local example = LDP.examples.SuperStar

local function superstarExample()
    local Build = LDP.Extra.Build

    local build = Build.GetLocalPlayerBuild()
    example.build = build

    if Zgoo then Zgoo.CommandHandler('LibDataPacker.examples.SuperStar') end

    local base64string = Build.GetPackedLocalPlayerBuild()
    example.base64string = base64string
    example.stringLength = #base64string

    local unpackedBuild = Build.UnpackBuild(base64string)
    example.unpackedBuild = unpackedBuild

    example.maxPossibleLength = Build.MaxLength

    if Zgoo then Zgoo.CommandHandler('LibDataPacker.examples.SuperStar') end

    --[[ BEFORE
    for hotbar = HOTBAR_CATEGORY_PRIMARY, HOTBAR_CATEGORY_BACKUP do
        for slot = 3, 8 do
            local slotBoundId = GetSlotBoundId(slot, hotbar)
            if GetSlotType(slot, hotbar) == ACTION_TYPE_CRAFTED_ABILITY then
                -- do something
            else
                -- do something
            end
        end
    end
    --]]

    for hotbar = HOTBAR_CATEGORY_PRIMARY, HOTBAR_CATEGORY_BACKUP do
        for slot = 3, 8 do
            local skillId = build:GetSlotBoundId(slot, hotbar)
            if build:GetSlotType(slot, hotbar) == ACTION_TYPE_CRAFTED_ABILITY then
                Log(GetCraftedAbilityDisplayName(skillId))
                Log(GetCraftedAbilityIcon(skillId))
            else
                Log(GetAbilityName(skillId))
                Log(GetAbilityIcon(skillId))
            end
        end
    end
end

example.run = superstarExample

do
    zo_callLater(example.run, 1000)
end