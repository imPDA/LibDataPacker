local NAME = 'UnitTests'

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

example.run = function()
    local Field = LDP.Field
    local Base = LDP.Base

    example.one = {}

    local bb1 = LDP.BinaryBuffer.New()
    bb1:Write(1234567890, 31)
    local bb2 = Base.Base64RCF4648:Encode(bb1)
    local bb3 = Base.Base64RCF4648:Decode(bb2)
    local bb4 = bb3:Read(31)
    example.one[1] = table.concat(bb1):reverse()
    example.one[2] = bb2
    example.one[3] = table.concat(bb3):reverse()
    example.one[4] = bb4
    -- example.one[4] = {}
    -- while example.one[3]:Available() do
    --     example.one[4][#example.one[4]+1] = example.one[3]:Read(6)
    -- end

    if Zgoo then Zgoo.CommandHandler('LibDataPacker.examples.' .. NAME) end

    local IGNORE_NAMES = true
    local INVERTED = true

    local schemas =
    {
        Field.Number(nil, 31),
        -- Field.Array(nil, 31),
        -- Field.VLArray(nil, 31),
        -- Field.Table(nil, 31),
        -- Field.Bool(nil, 31),
        -- Field.String(nil, 31),
        -- Field.Enum(nil, 31),
        -- Field.Optional(nil, 31),

    }
    local data = {
        1234567890,

    }
    example.data = data

    example.results = {}
    for i, field in ipairs(schemas) do
        example.results[i] = {}
        local bb = LDP.BinaryBuffer.New()
        field:Serialize(data[i], bb)
        example.results[i][1] = table.concat(bb)

        local packed = LDP.Pack(data[i], field)
        example.results[i][2] = packed
        example.results[i][3] = LDP.Unpack(packed, field)
    end

    if Zgoo then Zgoo.CommandHandler('LibDataPacker.examples.' .. NAME) end
end

-- do
--     zo_callLater(example.run, 1000)
-- end