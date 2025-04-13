local CLASSES_LOOKUP_TABLE = {
    1,
    2,
    3,
    4,
    5,
    6,
    117,
}

--[[ if Xivilai become a thing
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
--]]

local BOONS_ENUM = {
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
    [0]     = 14,   -- no Boon
}

local WW_OR_VAMPIRE_ENUM = {
    [135397] = 1,   -- Vampirism: Stage 1
    [135399] = 2,   -- Vampirism: Stage 2
    [135400] = 3,   -- Vampirism: Stage 3
    [135402] = 4,   -- Vampirism: Stage 4
    [35658]  = 5,   -- Lycantropy
    [0]      = 6,   -- not WW/Vamp
}

local CHAMPION_SLOTTABLE_SKILLS_LOOKUP_TABLE = {
    0,  -- no CP star slotted
    2,   3,   4,   5,   8,   9,   12,  13,  23,  24,  25,  26,  27,  28,  29,  30,
    31,  32,  33,  34,  35,  46,  47,  48,  49,  51,  52,  54,  55,  56,  57,  59,
    60,  61,  62,  63,  64,  65,  66,  76,  78,  80,  82,  84,  88,  89,  92,  133,
    134, 136, 159, 160, 161, 162, 163, 259, 260, 261, 262, 263, 264, 265, 266, 267,
    268, 270, 271, 272, 273, 274, 275, 276, 277,
}

local ATTRIBUTES_LOOKUP_TABLE = {
    ATTRIBUTE_HEALTH,  -- 1
    ATTRIBUTE_MAGICKA,  -- 2
    ATTRIBUTE_STAMINA,  -- 3
}

local GEAR_SLOTS = {
    EQUIP_SLOT_HEAD,  -- 0  
    EQUIP_SLOT_CHEST,  -- 2
    EQUIP_SLOT_SHOULDERS,  -- 3
    EQUIP_SLOT_HAND,  -- 16
    EQUIP_SLOT_WAIST,  -- 6
    EQUIP_SLOT_LEGS,  -- 8
    EQUIP_SLOT_FEET,  -- 9

    EQUIP_SLOT_NECK,  -- 1
    EQUIP_SLOT_RING1,  -- 11
    EQUIP_SLOT_RING2,  -- 12

    EQUIP_SLOT_MAIN_HAND,  -- 4
    EQUIP_SLOT_BACKUP_MAIN,  -- 20
    EQUIP_SLOT_OFF_HAND,  -- 5
    EQUIP_SLOT_BACKUP_OFF,  -- 21
}

-- ----------------------------------------------------------------------------

local function GetAlliance()    return GetUnitAlliance('player')        end
local function GetAvARank()     return GetUnitAvARank('player')         end
local function GetRace()        return GetUnitRaceId('player')          end
local function GetClass()       return GetUnitClassId('player')         end
local function GetLevel()       return GetUnitLevel('player')           end
local function GetCP()          return GetUnitChampionPoints('player')  end

local function GetSkills()
    local skills = {}

    for category = HOTBAR_CATEGORY_PRIMARY, HOTBAR_CATEGORY_BACKUP do
        skills[category] = {}
        for slot = 3, 8 do
            local slotBoundId = GetSlotBoundId(slot, category)
            if GetSlotType(slot, category) == ACTION_TYPE_CRAFTED_ABILITY then
                local script1, script2, script3 = GetCraftedAbilityActiveScriptIds(slotBoundId)
                skills[category][slot] = {
                    slotBoundId,
                    script1,
                    script2,
                    script3,
                }
            else
                skills[category][slot] = slotBoundId  -- or 0 if no skill in slot
            end
        end
    end

    return skills
end

local function GetBoon(index)
    local numBuffs = GetNumBuffs('player')
    if numBuffs == 0 then return end

    local boons = {}

    for i = 1, numBuffs do
        local _, _, _, _, _, _, _, _, _, _, abilityId = GetUnitBuffInfo('player', i)
        if BOONS_ENUM[abilityId] then
            boons[#boons+1] = abilityId
        end
    end

    table.sort(boons)

    return boons[index]
end

local function GetWWorVampireBuff()
    local numBuffs = GetNumBuffs('player')
    if numBuffs == 0 then return end

    for i = 1, numBuffs do
        local _, _, _, _, _, _, _, _, _, _, abilityId = GetUnitBuffInfo('player', i)
        if WW_OR_VAMPIRE_ENUM[abilityId] then
            return abilityId
        end
    end
end

local function GetAttributes()
    local attributes = {}

    for i = 1, #ATTRIBUTES_LOOKUP_TABLE do
        attributes[i] = GetAttributeSpentPoints(ATTRIBUTES_LOOKUP_TABLE[i])
    end

    return attributes
end

local STATS_LOOKUP_TABLE = {
    STAT_HEALTH_MAX,    -- 7
    STAT_MAGICKA_MAX,   -- 4
    STAT_STAMINA_MAX,   -- 29

    STAT_HEALTH_REGEN_COMBAT,   -- 8
    STAT_MAGICKA_REGEN_COMBAT,  -- 5
    STAT_STAMINA_REGEN_COMBAT,  -- 30

    STAT_POWER,         -- 35
    STAT_SPELL_POWER,   -- 25

    STAT_CRITICAL_STRIKE,   -- 16
    STAT_SPELL_CRITICAL,    -- 23

    STAT_PHYSICAL_PENETRATION,  -- 33
    STAT_SPELL_PENETRATION,     -- 34

    STAT_PHYSICAL_RESIST,   -- 22
    STAT_SPELL_RESIST,      -- 13
}

local function GetStats()
    local stats = {}

    local stat
    for i = 1, #STATS_LOOKUP_TABLE do
        stat = STATS_LOOKUP_TABLE[i]
        stats[STATS_LOOKUP_TABLE[i]] = GetPlayerStat(stat)
    end

    return stats
end

local function GetGearSlot(slot)
    local itemLink = GetItemLink(BAG_WORN, slot)
    if not itemLink or itemLink == '' then return {0, 0, 0, 0} end

    local itemId = GetItemLinkItemId(itemLink)
    local itemQuality = GetItemLinkDisplayQuality(itemLink)
    local itemTrait = GetItemLinkTraitInfo(itemLink)
    local itemEnchantId = GetItemLinkAppliedEnchantId(itemLink)
    -- local itemEnchantQuality = GetEnchantQuality(itemLink)

    return {itemId, itemQuality, itemTrait, itemEnchantId}
end

local function GetGear()
    local gear = {}

    local slot
    for i = 1, #GEAR_SLOTS do
        slot = GEAR_SLOTS[i]
        gear[slot] = GetGearSlot(slot)
    end

    return gear
end

local function GetConstellations()
    local constellations = {}

    for i = 1, 12 do
        constellations[i] = GetSlotBoundId(i, HOTBAR_CATEGORY_CHAMPION)
    end

    return constellations
end

-- ---------------------------------------------------------------------------

local LDP = LibDataPacker

local Field = LDP.Field
local BaseField = LDP.BaseField

local IGNORE_NAMES = true

-- ----------------------------------------------------------------------------

--- @class Skill : Field
--- @field __index Skill
local Skill = setmetatable({}, { __index = BaseField })
Skill.__index = Skill

--- Creates a new Enum field
--- @param name string|nil The field name
--- @param ignoreNames boolean|nil
--- @return Skill @The new Skills field
function Skill.New(name, ignoreNames)
    --- @class (partial) Skill
    local o = setmetatable(BaseField.New(name, 0), Skill)

    o.isCrafted = Field.Bool(nil)

    -- U45
    -- craftedAbilityId - 12 max
    -- scriptId - 70 max

    local craftedAbility = Field.Table(nil, {
        Field.Number('craftedSkillId', 6),
        Field.Number('script1', 7),
        Field.Number('script2', 7),
        Field.Number('script3', 7),
    }, ignoreNames)
    o.ignoreNames = ignoreNames

    o.ability = Field.Number(nil, 20)
    o.craftedAbility = craftedAbility

    return o
end

--- Handles a boolean value
--- @param data any The data to handle
function Skill:Serialize(data, binaryBuffer)
    if type(data) == 'table' then
        self.isCrafted:Serialize(true, binaryBuffer)
        self.craftedAbility:Serialize(data, binaryBuffer)
    else
        self.isCrafted:Serialize(false, binaryBuffer)
        self.ability:Serialize(data, binaryBuffer)
    end
end

function Skill:Unserialize(dataBuffer)
    local isCrafted = self.isCrafted:Unserialize(dataBuffer)

    if isCrafted then
        return self.craftedAbility:Unserialize(dataBuffer)
    else
        return self.ability:Unserialize(dataBuffer)
    end
end

function Skill:GetMaxBitLength()
    return self.isCrafted:GetMaxBitLength() + self.craftedAbility:GetMaxBitLength()
end

-- ----------------------------------------------------------------------------

local Skills = Field.Array('skills', 12, Skill.New(nil, true))

local MAX_SKILLS = 12
local MAX_CRAFTED_SKILLS = 10

function Skills:GetMaxBitLength()
    -- all crafted but ultimates
    return (1 + 27) * MAX_CRAFTED_SKILLS + 20 * (MAX_SKILLS - MAX_CRAFTED_SKILLS)
    -- return (1 + 27) * MAX_SKILLS
end

local Stats = Field.Table('stats', {
    Field.Number(STAT_HEALTH_MAX,   16),
    Field.Number(STAT_MAGICKA_MAX,  16),
    Field.Number(STAT_STAMINA_MAX,  16),

    Field.Number(STAT_HEALTH_REGEN_COMBAT,  14),
    Field.Number(STAT_MAGICKA_REGEN_COMBAT, 14),
    Field.Number(STAT_STAMINA_REGEN_COMBAT, 14),

    Field.Number(STAT_POWER,        14),
    Field.Number(STAT_SPELL_POWER,  14),

    Field.Number(STAT_CRITICAL_STRIKE,  15),
    Field.Number(STAT_SPELL_CRITICAL,   15),

    Field.Number(STAT_PHYSICAL_PENETRATION, 16),
    Field.Number(STAT_SPELL_PENETRATION,    16),

    Field.Number(STAT_PHYSICAL_RESIST,  17),
    Field.Number(STAT_SPELL_RESIST,     17),
})

local Item = Field.Table('item', {
    Field.Number('id',              20),
    Field.Number('quality',         3),
    Field.Number('trait',           6),
    Field.Number('enchantmentId',   20),
}, IGNORE_NAMES)

local Build = Field.Table(nil, {
    Field.Number('alliance',        2),
    Field.Number('avaRank',         6),

    Field.Number('race',            3),
    Field.Enum('class', CLASSES_LOOKUP_TABLE, true),

    -- Field.Number('skillPoints',     10),

    Field.Number('level', 6),
    Field.Number('CP', 12),

    Skills,

    Field.Enum('boon1', BOONS_ENUM),
    Field.Enum('boon2', BOONS_ENUM),

    Field.Enum('WWorVampire', WW_OR_VAMPIRE_ENUM),

    Field.Array('attributes',   3,  Field.Number(nil, 7)),

    Stats,

    Field.Array('gear', 14, Item),

    Field.Array('constellations', 12, Field.Enum(nil, CHAMPION_SLOTTABLE_SKILLS_LOOKUP_TABLE, true)),
}, IGNORE_NAMES)

-- ----------------------------------------------------------------------------

local function convertToArray(table, lookupTable)
    local array = {}

    for i = 1, #lookupTable do
        array[i] = table[lookupTable[i]] or error(('Element #%d was not found'):format(lookupTable[i]))
    end

    return array
end

local function convertToIndexedTable(array, lookupTable)
    local indexedTable = {}

    for i = 1, #array do
        indexedTable[lookupTable[i]] = array[i]
    end

    return indexedTable
end

local function flattenSkills(skillsTable)
    local flatArray = {}

    for _, hotbar in pairs(skillsTable) do
        for _, skill in pairs(hotbar) do
            flatArray[#flatArray+1] = skill
        end
    end

    return flatArray
end

local function unflattenSkills(flatArray)
    local skillsTable = {
        [HOTBAR_CATEGORY_PRIMARY] = {},
        [HOTBAR_CATEGORY_BACKUP] = {},
    }

    for i, skill in ipairs(flatArray) do
        skillsTable[math.floor(i / 7)][i % 7 + 2] = skill
    end

    return skillsTable
end

-- ----------------------------------------------------------------------------

local ALLIANCE          = 1
local AVA_RANK          = 2
local RACE              = 3
local CLASS             = 4
local LEVEL             = 5
local CP                = 6
local SKILLS            = 7
local FIRST_BOON        = 8
local SECOND_BOON       = 9
local WW_VAMP_BUFF      = 10
local ATTRIBUTES        = 11
local STATS             = 12
local GEAR              = 13
local CONSTELLATIONS    = 14

local BUILD = {
    [ALLIANCE]          = GetAlliance,
    [AVA_RANK]          = GetAvARank,
    [RACE]              = GetRace,
    [CLASS]             = GetClass,
    [LEVEL]             = GetLevel,
    [CP]                = GetCP,
    [SKILLS]            = GetSkills,
    [FIRST_BOON]        = function() GetBoon(1) end,
    [SECOND_BOON]       = function() GetBoon(2) end,
    [WW_VAMP_BUFF]      = GetWWorVampireBuff,
    [ATTRIBUTES]        = GetAttributes,
    [STATS]             = GetStats,
    [GEAR]              = GetGear,
    [CONSTELLATIONS]    = GetConstellations,
}

local function GetSlotType(build, slot, hotbar)
    if hotbar ~= HOTBAR_CATEGORY_PRIMARY and hotbar ~= HOTBAR_CATEGORY_BACKUP then
        error(('Wrong hotbar category: "%s"'):format(GetString('SI_HOTBARCATEGORY', hotbar)))
    end

    return type(build[SKILLS][hotbar][slot]) == 'table' and ACTION_TYPE_CRAFTED_ABILITY or ACTION_TYPE_ABILITY
end

local function GetSlotBoundId(build, slot, hotbar)
    if hotbar == HOTBAR_CATEGORY_PRIMARY or hotbar == HOTBAR_CATEGORY_BACKUP then
        local skill = build[SKILLS][hotbar][slot]
        if type(skill) == 'table' then
            return skill[1]
        else
            return skill
        end
    elseif hotbar == HOTBAR_CATEGORY_CHAMPION then
        return build[CONSTELLATIONS][slot]
    else
        error(('Wrong hotbar category: "%s"'):format(GetString('SI_HOTBARCATEGORY', hotbar)))
    end
end

local function GetSlotScriptIds(build, slot, hotbar)
    if GetSlotType(build, slot, hotbar) ~= ACTION_TYPE_CRAFTED_ABILITY then return end

    local skill = build[SKILLS][hotbar][slot]

    return skill[2], skill[3], skill[4]
end

local function GetPlayerStat(build, stat)
    return build[STATS][stat]
end

local mt = {
    __index = {
        GetSlotType = GetSlotType,
        GetSlotBoundId = GetSlotBoundId,
        GetPlayerStat = GetPlayerStat,
        GetSlotScriptIds = GetSlotScriptIds,
    },
}

-- ----------------------------------------------------------------------------

local function GetLocalPlayerBuild()
    local build = {}

    for i = 1, #BUILD do
        build[i] = BUILD[i]()
    end

    setmetatable(build, mt)

    return build
end

local function PackBuild(build)
    build[SKILLS] = flattenSkills(build[SKILLS])
    build[FIRST_BOON] = build[FIRST_BOON] or 0
    build[SECOND_BOON] = build[SECOND_BOON] or 0
    build[WW_VAMP_BUFF] = build[WW_VAMP_BUFF] or 0
    build[GEAR] = convertToArray(build[GEAR], GEAR_SLOTS)

    return LDP.Pack(build, Build, LDP.Base.Base64LinkSafe)
end

local function GetPackedLocalPlayerBuild()
    return PackBuild(GetLocalPlayerBuild())
end

local function UnpackBuild(packedBuild)
    local build = LDP.Unpack(packedBuild, Build, LDP.Base.Base64LinkSafe)

    build[SKILLS] = unflattenSkills(build[SKILLS])
    build[FIRST_BOON] = build[FIRST_BOON] ~= 0 and build[FIRST_BOON] or nil
    build[SECOND_BOON] = build[SECOND_BOON] ~= 0 and build[SECOND_BOON] or nil
    build[WW_VAMP_BUFF] = build[WW_VAMP_BUFF] ~= 0 and build[WW_VAMP_BUFF] or nil
    build[GEAR] = convertToIndexedTable(build[GEAR], GEAR_SLOTS)

    setmetatable(build, mt)

    return build
end

LDP.Extra = LDP.Extra or {}
LDP.Extra.Build = {
    ALLIANCE        = ALLIANCE,
    AVA_RANK        = AVA_RANK,
    RACE            = RACE,
    CLASS           = CLASS,
    LEVEL           = LEVEL,
    CP              = CP,
    SKILLS          = SKILLS,
    FIRST_BOON      = FIRST_BOON,
    SECOND_BOON     = SECOND_BOON,
    WW_VAMP_BUFF    = WW_VAMP_BUFF,
    ATTRIBUTES      = ATTRIBUTES,
    STATS           = STATS,
    GEAR            = GEAR,
    CONSTELLATIONS  = CONSTELLATIONS,

    GetLocalPlayerBuild = GetLocalPlayerBuild,
    GetPackedLocalPlayerBuild = GetPackedLocalPlayerBuild,
    UnpackBuild = UnpackBuild,
    GetSlotType = GetSlotType,
}
