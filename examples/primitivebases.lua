local NAME = 'PrimitiveBases'

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

    local IGNORE_NAMES = true
    local INVERTED = true

    local AMOUNT = 6

    local schema = Field.Array(nil, AMOUNT,
        Field.Array(nil, 128,
            Field.Array(nil, 2, Field.Number(nil, 7))
        )
    )
    local data = {}

    for i = 0, AMOUNT-1 do
        data[i+1] = {}
        for j = 0, 127 do
            data[i+1][j+1] = {j, i}
        end
    end

    example.data = data

    if ImpData1 and ImpData1.data and ImpData1.data ~= '' then
        example.unpackedSV = LDP.Unpack(ImpData1.data, schema, LDP.Base.Base128Primitive)
        example.equals = equals(example.unpackedSV, data, false)
    end

    example.base64string = LDP.Pack(data, schema)
    example.base64length = #example.base64string
    -- Log('Base64 string: %s', example.base64string)

    example.base128string = LDP.Pack(data, schema, LDP.Base.Base128Primitive)
    example.base128length = #example.base128string
    -- Log('Base128 string: %s', example.base128string)

    example.unpacked64String = LDP.Unpack(example.base64string, schema)
    example.unpacked128String = LDP.Unpack(example.base128string, schema, LDP.Base.Base128Primitive)

    if Zgoo then Zgoo.CommandHandler('LibDataPacker.examples.' .. NAME) end

    -- if ImpData1 then
    --     Log('ImpData1 - %s', tostring(ImpData1.data == example.base256string))
    -- end

    ImpData1 = {
        data = example.base128string
    }
end

-- do
--     zo_callLater(example.run, 1000)
-- end