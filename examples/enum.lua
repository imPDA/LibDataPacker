local Log = LibDataPacker_Logger()

local LDP = LibDataPacker
LDP.examples = LDP.examples or {}
LDP.examples.Enum = {}

local example = LDP.examples.Enum

-- ----------------------------------------------------------------------------

local skillsLookupTable = {}
do
    for i = 1, 100 do
        skillsLookupTable[i] = 100000 + i
    end
end

local function generateSkills(number)
    local skillsArray = {}

    for i = 1, number do
        skillsArray[i] = skillsLookupTable[math.random(#skillsLookupTable)]
    end

    return skillsArray
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

-- ----------------------------------------------------------------------------

local function enumExample()
    local Field = LDP.Field

    local IGNORE_NAMES = true
    local INVERTED = true

    local skill = Field.Enum('skill', skillsLookupTable, INVERTED)

    local schema = Field.Table(nil, {
        Field.Array('front panel', 6, skill),
        Field.Array('back panel', 6, skill),
    }, IGNORE_NAMES)


    local data = {
        generateSkills(6),
        generateSkills(6),
    }

    example.data = data

    example.base64string = LDP.Pack(data, schema)
    example.base64length = #example.base64string
    Log('Base64 string: %s', example.base64string)

    example.base256string = LDP.Pack(data, schema, LDP.Base.Base256LibBinaryEncode)
    example.base256length = #example.base256string
    Log('Base256 string: %s', example.base256string)

    example.unpackedData1 = LDP.Unpack(example.base64string, schema)
    example.equals1 = equals(example.data, example.unpackedData1, false)

    example.unpackedData2 = LDP.Unpack(example.base256string, schema, LDP.Base.Base256LibBinaryEncode)
    example.equals2 = equals(example.data, example.unpackedData2, false)

    if Zgoo then
        Zgoo.CommandHandler('LibDataPacker.examples.Enum')
    end
end

example.run = enumExample