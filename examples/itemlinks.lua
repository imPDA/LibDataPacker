local NAME = 'ItemLinks'

-- ----------------------------------------------------------------------------

local Log = LibDataPacker_Logger()

local LDP = LibDataPacker

LDP.examples = LDP.examples or {}
LDP.examples[NAME] = {}
local example = LDP.examples[NAME]

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

--[[
    1: Id -- The ID of the base object (1-80000).
    2: SubType -- Some combination of the item's quality and VR level (0-370, see below).
    3: InternalLevel -- Value from 0-50 indicating the item's level. Note that VR levels always have a value of 50 here with the VR level indicated by the previous SubType field.
    4: EnchantID -- The ID of any enchantment on the item (0-80000) or 0 for none.
    5: EnchantSubType -- Appears to be the same as the item's SubType field described above but applied to the enchantment (0-317).
    6: EnchantLevel -- Internal level of the enchantment (0-50, like the item level).
    7: TransmuteTrait -- For transmuted items this is the new trait value for the item. Added in update 16 (Clockwork City).
    7: Writ1 -- This and the next 5 fields are only used in master writs and contain the exact requirement for the writ. See below for more detail.
    8: Writ2 --
    9: Writ3 --
    10: Writ4 --
    11: Writ5 --
    12: Writ6 --
    13:
    14:
    15: Flags -- (see below for details)
    16: ItemStyle -- (0-?, see below for details)
    17: Crafted -- If 1 then the item is player crafted (0/1)
    18: Bound -- If 1 (non-zero?) then the item is bound to the player (0/1)
    19: Stolen -- Added in Update 6 this will be 1 for stolen goods and 0 for everything else (0/1)
    20: Charges -- The number of charges left on the weapon, or the condition (in percent x100) left on the armor (0-?)
    21: PotionEffect -- Custom potions seem to have a large value in this field (0-?, see below for details).
    21: WritReward -- Divide this value by 10000 and round up to obtain the voucher reward value (0.50 is rounded up).
--]]

local strings = {
    "|H1:item:59489:364:50:68343:370:50:0:0:0:0:0:0:0:0:1:67:0:1:0:6090:0|h|h",
}

local FLAGS = {
    1, 16, 256, 2048
}

local function extractValues(inputString)
    -- Pattern to match the content between |H1: and |h|h
    local pattern = "|H1:item:(.-)|h|h"
    local content = inputString:match(pattern)

    if not content then
        return nil, "Pattern not found in input string"
    end

    -- Split the content by colons
    local values = {}
    for value in content:gmatch("([^:]+)") do
        table.insert(values, tonumber(value))
    end

    return values
end

example.run = function()
    local Field = LDP.Field

    local IGNORE_NAMES = true
    local INVERTED = true

    local AMOUNT = 1

    local schema = Field.Table('item', {
        --[[ 1]] Field.Number('Id',              18),
        --[[ 2]] Field.Number('SubType',         9),
        --[[ 3]] Field.Number('InternalLevel',   6),
        --[[ 4]] Field.Number('EnchantID',       18),
        --[[ 5]] Field.Number('EnchantSubType',  9),
        --[[ 6]] Field.Number('EnchantLevel',    6),
        --[[ 7]] Field.Number('TransmuteTrait/Writ1', 10),
        --[[ 8]] Field.Number('Writ2',           10),
        --[[ 9]] Field.Number('Writ3',           10),
        --[[10]] Field.Number('Writ4',           10),
        --[[11]] Field.Number('Writ5',           10),
        --[[12]] Field.Number('Writ6',           10),
        --[[13]] Field.Number('???',             1),
        --[[14]] Field.Number('???',             1),
        --[[15]] Field.Enum('Flags', FLAGS, INVERTED),
        --[[16]] Field.Number('ItemStyle',       9),
        --[[17]] Field.Number('Crafted',         1),
        --[[18]] Field.Number('Bound',           1),
        --[[19]] Field.Number('Stolen',          1),
        --[[20]] Field.Number('Charges',         14),
        --[[21]] Field.Number('PotionEffect/WritReward', 24),
    }, IGNORE_NAMES)

    local data = {}
    for _ = 1, 10000 do
        for _, string in ipairs(strings) do
            data[#data+1] = extractValues(string)
        end
    end
    example.data = data

    if Zgoo then Zgoo.CommandHandler('LibDataPacker.examples.' .. NAME) end

    local start, stop

    local packedData = {}
    start = GetGameTimeMilliseconds()
    for i = 1, #data do
        packedData[i] = LDP.Pack(data[i], schema)
    end
    stop = GetGameTimeMilliseconds()
    example.packedData = packedData
    example.packDuration = ('%.6f ms per pack'):format((stop - start) / 10000)

    local unpackedData = {}
    start = GetGameTimeMilliseconds()
    for i = 1, #packedData do
        unpackedData[i] = LDP.Unpack(packedData[i], schema)
    end
    stop = GetGameTimeMilliseconds()
    example.unpackedData = unpackedData
    example.unpackDuration = ('%.6f ms per unpack'):format((stop - start) / 10000)

    if Zgoo then Zgoo.CommandHandler('LibDataPacker.examples.' .. NAME) end
end

-- do
--     zo_callLater(example.run, 1000)
-- end