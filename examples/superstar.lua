local CLASSES_LOOKUP_TABLE = {
    1, 2, 3, 4, 5, 6, 117
}

local RACES_LOOKUP_TABLE = {
    1,  -- Breton
    2,  -- Redguard
    3,  -- Orc
    4,  -- Dark Elf
    5,  -- Nord
    6,  -- Argonian
    7,  -- High Elf
    8,  -- Wood Elf
    9,  -- Khajiit
    10, -- Imperial
    -- 29,  -- Xivilai
}

--#region PREPARATIONS
local MUNDUS_BOONS_ENUM = {
    [13940] = 1,    -- Boon: The Warrior
    [13943] = 2,    -- Boon: The Mage
    [13974] = 3,    -- Boon: The Serpent
    [13975] = 4,    -- Boon: The Thief
    [13976] = 5,    -- Boon: The Lady
    [13977] = 6,    -- Boon: The Steed
    [13978] = 7,    -- Boon: The Lord
    [13979] = 8,    -- Boon: The Apprentice
    [13980] = 9,    -- Boon: The Ritual
    [13981] = 10,   -- Boon: The Lover
    [13982] = 11,   -- Boon: The Atronach
    [13984] = 12,   -- Boon: The Shadow
    [13985] = 13,   -- Boon: The Tower
}

local VAMPIRE_OR_WW_ENUM = {
    [135397] = 1,   -- Vampirism: Stage 1
    [135399] = 2,   -- Vampirism: Stage 2
    [135400] = 3,   -- Vampirism: Stage 3
    [135402] = 4,   -- Vampirism: Stage 4
    [35658] = 5,    -- Lycantropy
}

local CHAMPION_SLOTTABLE_SKILLS_LOOKUP_TABLE = {
    0,  -- no CP star slotted
    2,  3,  4,  5,  8,  9,  12, 13, 23, 24, 25, 26, 27, 28, 29, 30,
    31, 32, 33, 34, 35, 46, 47, 48, 49, 51, 52, 54, 55, 56, 57, 59,
    60, 61, 62, 63, 64, 65, 66, 76, 78, 80, 82, 84, 88, 89, 92, 133,
    134,136,159,160,161,162,163,259,260,261,262,263,264,265,266,267,
    268,270,271,272,273,274,275,276,277,
}

local DATA_MAP = {
    {  -- 1
        name = 'alliance',
        callback = function()
            return GetUnitAlliance('player')
        end,
        binarySize = 2,
    },
    {  -- 2
        name = 'race',
        callback = function()
            return GetUnitRaceId('player')
        end,
        binarySize = 3,
    },
    {  -- 3
        name = 'class',
        callback = function()
            local class = GetUnitClassId('player')
            -- return class == 117 and 7 or class
            return class
        end,
        binarySize = 3,
    },
    {  -- 4
        name = 'ava rank',
        callback = function()
            return GetUnitAvARank('player')
        end,
        binarySize = 3,
    },
    -- {  -- 5
    --     name = 'available skill points',
    --     callback = function()
    --         return GetAvailableSkillPoints()
    --     end,
    --     binarySize = 10,
    -- },
    {  -- 6
        name = 'level',
        callback = function()
            return GetUnitLevel('player')
        end,
        -- binarySize = 12,
    },
    {  -- 6
        name = 'cp',
        callback = function()
            return GetUnitChampionPoints('player')
        end,
        -- binarySize = 12,
    },
    {  -- 7
        name = 'skills',
        callback = function(category, slot)
            return GetSlotBoundId(slot, category)  -- 2^20 - 1 = 1048575
        end,
        args = {{HOTBAR_CATEGORY_PRIMARY, HOTBAR_CATEGORY_BACKUP}, {3, 4, 5, 6, 7, 8}},
        binarySize = 20,
    },
    {  -- 8
        name = 'mundus1',
        callback = function(index)
            local numBuffs = GetNumBuffs('player')
            if numBuffs == 0 then return end

            local munduses = {}
            for i = 1, numBuffs do
                local _, _, _, _, _, _, _, _, _, _, abilityId = GetUnitBuffInfo('player', i)
                if MUNDUS_BOONS_ENUM[abilityId] then
                    table.insert(munduses, abilityId)
                end
            end

            return munduses[index]
        end,
        args = {1},
        binarySize = 4,
    },
    {  -- 8
        name = 'mundus2',
        callback = function(index)
            local numBuffs = GetNumBuffs('player')
            if numBuffs == 0 then return end

            local munduses = {}
            for i = 1, numBuffs do
                local _, _, _, _, _, _, _, _, _, _, abilityId = GetUnitBuffInfo('player', i)
                if MUNDUS_BOONS_ENUM[abilityId] then
                    table.insert(munduses, abilityId)
                end
            end

            return munduses[index]
        end,
        args = {2},
        binarySize = 4,
    },
    {  -- 9
        name = 'vampire/ww',
        callback = function()
            local numBuffs = GetNumBuffs('player')
            if numBuffs == 0 then return end

            for i = 1, numBuffs do
                local _, _, _, _, _, _, _, _, _, _, abilityId = GetUnitBuffInfo('player', i)
                if VAMPIRE_OR_WW_ENUM[abilityId] then
                    return abilityId
                end
            end
        end,
        binarySize = 3,
    },
    {  -- 10
        name = 'attributes',
        callback = function(attribute)
            return GetAttributeSpentPoints(attribute)
        end,
        args = {{ATTRIBUTE_HEALTH, ATTRIBUTE_MAGICKA, ATTRIBUTE_STAMINA}},
        binarySize = 7,
    },
    {  -- 11
        name = 'max resources',
        callback = function(resourceType)
            return GetPlayerStat(resourceType)
        end,
        args = {{STAT_HEALTH_MAX, STAT_MAGICKA_MAX, STAT_STAMINA_MAX}},
        binarySize = 16,
    },
    {  -- 12
        name = 'regens',
        callback = function(resourceType)
            return GetPlayerStat(resourceType)
        end,
        args = {{STAT_HEALTH_REGEN_COMBAT, STAT_MAGICKA_REGEN_COMBAT, STAT_STAMINA_REGEN_COMBAT}},
        binarySize = 14,
    },
    {  -- 13
        name = 'wpd/spd',
        callback = function(type)
            return GetPlayerStat(type)
        end,
        args = {{STAT_SPELL_POWER, STAT_POWER}},
        binarySize = 14,
    },
    {  -- 14
        name = 'wpd/spd critrate',
        callback = function(type)
            return GetPlayerStat(type)
        end,
        args = {{STAT_SPELL_CRITICAL, STAT_CRITICAL_STRIKE}},
        binarySize = 15,
    },
    {  -- 15
        name = 'penetrations',
        callback = function(type)
            return GetPlayerStat(type)
        end,
        args = {{STAT_SPELL_PENETRATION, STAT_PHYSICAL_PENETRATION}},
        binarySize = 16,
    },
    {  -- 16
        name = 'resistances',
        callback = function(type)
            return GetPlayerStat(type)
        end,
        args = {{STAT_SPELL_RESIST, STAT_PHYSICAL_RESIST}},
        binarySize = 17,
    },
    {  -- 17
        name = 'gear',
        callback = function(slot)
            local itemLink = GetItemLink(BAG_WORN, slot)
            if not itemLink or itemLink == '' then return end

            local itemId = GetItemLinkItemId(itemLink)
            local itemQuality = GetItemLinkDisplayQuality(itemLink)
            local itemTrait = GetItemLinkTraitInfo(itemLink)
            local itemEnchantId = GetItemLinkAppliedEnchantId(itemLink)
            -- local itemEnchantQuality = GetEnchantQuality(itemLink)

            return {{itemId, itemQuality, itemTrait, itemEnchantId}}
        end,
        args = {{
            EQUIP_SLOT_HEAD,
            EQUIP_SLOT_CHEST,
            EQUIP_SLOT_SHOULDERS,
            EQUIP_SLOT_HAND,
            EQUIP_SLOT_WAIST,
            EQUIP_SLOT_LEGS,
            EQUIP_SLOT_FEET,

            EQUIP_SLOT_NECK,
            EQUIP_SLOT_RING1,
            EQUIP_SLOT_RING2,

            EQUIP_SLOT_MAIN_HAND,
            EQUIP_SLOT_BACKUP_MAIN,
            EQUIP_SLOT_OFF_HAND,
            EQUIP_SLOT_BACKUP_OFF,
        }},
        binarySize = {20, 3, 6, 20},
    },
    {  -- 18
        name = 'champion star',
        callback = function(slot)
            return GetSlotBoundId(slot, HOTBAR_CATEGORY_CHAMPION)
            -- GetChampionAbilityId(*integer* _championSkillId_)
        end,
        args = {{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12}},
        binarySize = 14,
    },
}

local function TableConcat(t1, t2)
    if type(t2) ~= 'table' then
        t1[#t1+1] = t2
    else
        for i=1, #t2 do
            t1[#t1 + 1] = t2[i]
        end
    end
end

local function call(callback, args_, level)
    if args_ and type(args_[level]) == 'table' then
        local results = {}

        for _, arg in ipairs(args_[level]) do
            local newArgs = {}
            for i = 1, level-1 do
                newArgs[i] = args_[i]
            end
            newArgs[#newArgs+1] = arg
            TableConcat(newArgs, {select(level + 1, unpack(args_))})
            TableConcat(results, call(callback, newArgs, level + 1))
            -- results[#results+1] = call(callback, newArgs, level + 1)
        end

        return results
    end

    return args_ and callback(unpack(args_)) or callback()
end


local function collectData()
    local data = {}

    for i = 1, 19 do
        local dataPiece = DATA_MAP[i]
        data[i] = call(dataPiece.callback, dataPiece.args, 1)
    end

    return data
end

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
--#endregion

-- ----------------------------------------------------------------------------

-- 2^10-1 =         1.023
-- 2^12-1 =         4.095
-- 2^14-1 =        16.383
-- 2^15-1 =        32.767
-- 2^16-1 =        65.535
-- 2^17-1 =       131.071
-- 2^20-1 =     1.048.575

-- ----------------------------------------------------------------------------

local LDP = LibDataPacker
LDP.examples = LDP.examples or {}
LDP.examples.SuperStar = {}

local example = LDP.examples.SuperStar

local function superstarExample()
    local Field = LDP.Field

    local IGNORE_NAMES = true

    local item = Field.Table('item', {
        Field.Number('id',              20),
        Field.Number('quality',         3),
        Field.Number('trait',           6),
        Field.Number('enchantmentId',   20),
    }, IGNORE_NAMES)

    local superStarDataSchema = Field.Table(nil, {
        Field.Number('alliance',        2),
        Field.Number('avaRank',         6),

        Field.Number('race',            3),
        Field.Enum('class', CLASSES_LOOKUP_TABLE, true),

        -- Field.Number('skillPoints',     10),

        Field.Number('level', 6),
        Field.Number('CP', 12),

        Field.Array('skills', 12, Field.Number(nil, 20)),

        Field.Optional(Field.Enum('mundus1', MUNDUS_BOONS_ENUM)),
        Field.Optional(Field.Enum('mundus2', MUNDUS_BOONS_ENUM)),

        Field.Optional(Field.Enum('vampireOrWW', VAMPIRE_OR_WW_ENUM)),

        -- HP / magica / stamina
        Field.Array('attributes',   3,  Field.Number(nil, 7)),
        Field.Array('resources',    3,  Field.Number(nil, 16)),
        Field.Array('regens',       3,  Field.Number(nil, 14)),

        Field.Array('wpd/spd',      2,  Field.Number(nil, 14)),
        Field.Array('critrate',     2,  Field.Number(nil, 15)),
        Field.Array('penetration',  2,  Field.Number(nil, 16)),
        Field.Array('resistance',   2,  Field.Number(nil, 17)),

        Field.Array('gear', 14, item),

        Field.Array('stars', 12, Field.Enum(nil, CHAMPION_SLOTTABLE_SKILLS_LOOKUP_TABLE, true)),
    }, IGNORE_NAMES)

-- ------------------------------------------------------------------------

    local data = collectData()
    example.data = data

    local base64string = LDP.Pack(data, superStarDataSchema)
    example.base64string = base64string
    example.stringLength = #base64string

    local unpackedData = LDP.Unpack(base64string, superStarDataSchema)
    example.unpackedData = unpackedData

    superStarDataSchema.ignoreNames = false
    local unpackedDataStringIndexed = LDP.Unpack(base64string, superStarDataSchema)
    example.unpackedDataStringIndexed = unpackedDataStringIndexed

    example.equals = equals(data, unpackedData, false)

    if Zgoo then
        Zgoo.CommandHandler('LibDataPacker.examples.SuperStar')
    end
end

example.run = superstarExample

do
    zo_callLater(example.run, 1000)
end