local Log = LibDataPacker_Logger()

local lib = {}

-- ----------------------------------------------------------------------------

--- Converts a decimal number to a binary string of specified length.
--- @param decimal integer The decimal number to convert
--- @param bitLength integer The desired length of the binary string
--- @return string The binary string representation with leading zeros
local function decimalToBinaryString(decimal, bitLength)
    local binaryString = ''

    while decimal > 0 do
        binaryString = (decimal % 2 == 1 and '1' or '0') .. binaryString
        decimal = math.floor(decimal / 2)
    end

    return string.rep('0', bitLength - #binaryString) .. binaryString
end

--[[  -- TODO: test
function byte_to_binary(byte)
    local binary = ""
    for i = 7, 0, -1 do
        binary = binary .. (byte >> i & 1)
    end
    return binary
end
]]

--- Converts a binary string to a decimal number.
--- @param binaryString string The binary string to convert
--- @return integer The resulting decimal number
local function binaryStringToDecimal(binaryString)
    local dec = 0

    for i = 1, #binaryString do
        local bit = binaryString:sub(i, i)
        dec = dec * 2 + (bit == '1' and 1 or 0)
    end

    return dec
end

-- ----------------------------------------------------------------------------

local Buffer = {}
Buffer.__index = Buffer

function Buffer.New(data)
    local instance = setmetatable({}, Buffer)

    instance.data = data
    instance.pointer = #data

    return instance
end

function Buffer:Read(len)
    self.pointer = self.pointer - len
    return self.data:sub(self.pointer + 1, self.pointer + len)
end

-- ----------------------------------------------------------------------------

--- @class Base
--- @field __index Base
--- @field alphabet string The alphabet to use
--- @field encodeTable table Encode table based on alphabet 
--- @field lookupTable table Lookup table based on alphabet 
--- @field bitLength integer Bit length of one charater from the alphabet
local Base = {}
Base.__index = Base

function Base.FromAlphabet(alphabet)
    Log('Alphabet: %s', alphabet)

    local concreteBase = {}

    setmetatable(concreteBase, { __index = Base })
    concreteBase.__index = concreteBase

    concreteBase.alphabet = alphabet
    concreteBase.bitLength = math.floor(math.log(#alphabet) / math.log(2))

    Log('Alphabet length: %d, bit length: %d', #alphabet, concreteBase.bitLength)

    local lookupTable = {}
    for i = 1, #alphabet do
        lookupTable[alphabet:sub(i, i)] = i - 1
    end

    concreteBase.lookupTable = lookupTable

    return concreteBase
end

function Base:Encode(binaryString)
    local encodedString = ''

    for i = #binaryString, 1, -self.bitLength do
        local startIndex = i - self.bitLength + 1 > 1 and i - self.bitLength + 1 or 1
        local dec = binaryStringToDecimal(binaryString:sub(startIndex, i))
        encodedString = encodedString .. self.alphabet:sub(dec+1, dec+1)
    end

    return encodedString
end

function Base:Decode(encodedString)
    local binaryString = ''

    for i = 1, #encodedString do
        local decimal = self.lookupTable[encodedString:sub(i, i)]
        binaryString = decimalToBinaryString(decimal, self.bitLength) .. binaryString
    end

    return binaryString
end

local Base64RCF4648 = Base.FromAlphabet('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/')
local Base64LinkSafe = Base.FromAlphabet('23456789CFGHJMPQRVWXcfghjmpqrvwx01bBdDkKlLsStT!@#&=_{};,<>`~-]*/')

-- ----------------------------------------------------------------------------

local EMPTY = 0
local NUMERIC = 1
local TABLE = 2
local ARRAY = 3
local BOOLEAN = 4
local STRING = 5

--- @class Field
--- @field __index Field
--- @field name string|nil The field name
--- @field fieldType integer The field type (EMPTY, NUMERIC, TABLE, ARRAY)
-- @field fullBitLength integer The full bit length of entire field
local Field = {}
Field.__index = Field

--- Creates a new Field object
--- @param name string|nil The field name
--- @param fieldType integer The field type
--- @return Field @The new Field object
function Field.New(name, fieldType)
    --- @class (partial) Field
    local o = setmetatable({}, Field)

    o.name = name
    o.fieldType = fieldType

    return o
end

function Field:Serialize(data)
    assert(false, 'Must be overridden')
end

function Field:Unserialize(data)
    assert(false, 'Must be overridden')
end

-- ----------------------------------------------------------------------------

--- @class Numeric : Field
--- @field __index Numeric
--- @field bitLength integer The bit length for the numeric field
-- @field fullBitLength integer The full bit length of entire numeric field (same as bitLength actually)
local Numeric = setmetatable({}, { __index = Field })
Numeric.__index = Numeric

--- Creates a new Numeric field
--- @param name string|nil The field name
--- @param bitLength integer The bit length for the numeric field
--- @return Numeric @The new Numeric field
function Numeric.New(name, bitLength)
    --- @class (partial) Numeric
    local o = setmetatable(Field.New(name, NUMERIC), Numeric)

    o.bitLength = bitLength
    -- o.fullBitLength = o.bitLength

    return o
end

--- Handles a numeric value
--- @param data number The numeric data to handle
--- @return string|nil The binary string representation, or nil on error
function Numeric:Serialize(data)
    if not assert(type(data) == 'number', 'Value must be a number.') then
        return
    end

    local result = decimalToBinaryString(data, self.bitLength)

    if #result > self.bitLength then
        local ERROR = 'Value is outside of upper bound'
        Log('%s, data: %s, result: %d, maxlength: %d', ERROR, data, result, self.bitLength)
        error(ERROR)
    end

    return result
end

function Numeric:Unserialize(dataBuffer)
    -- TODO: length check
    local data = dataBuffer:Read(self.bitLength)
    return binaryStringToDecimal(data)
end

-- ----------------------------------------------------------------------------

--- @class Array : Field
--- @field __index Array
--- @field length integer The array length
--- @field subType Field The field type for array elements
-- @field fullBitLength integer The full bit length of entire array
local Array = setmetatable({}, { __index = Field })
Array.__index = Array

--- Creates a new Array field
--- @param name string|nil The field name
--- @param length integer The array length
--- @param subtype Field The field type for array elements
--- @return Array The new Array field
function Array.New(name, length, subtype)
    --- @class (partial) Array
    local o = setmetatable(Field.New(name, ARRAY), Array)

    o.length = length
    o.subType = subtype
    -- o.fullBitLength = subtype.fullBitLength * o.length

    return o
end

--- Handles an array of values
--- @param data table The array data to handle
--- @return string|nil The binary string representation, or nil on error
function Array:Serialize(data)
    local result = ''

    if not assert(type(data) == 'table', 'Value must be a table.') then
        return
    end

    for _, datum in ipairs(data) do
        result = result .. self.subType:Serialize(datum)
    end

    return result
end

function Array:Unserialize(dataBuffer)
    local result = {}

    -- TODO: length check

    for i = self.length, 1, -1 do
        result[i] = self.subType:Unserialize(dataBuffer)
    end

    return result
end

-- ----------------------------------------------------------------------------

--- @class Table : Field
--- @field __index Table
--- @field fields Field[] The fields contained in the table
local Table = setmetatable({}, { __index = Field })
Table.__index = Table

--- Creates a new Table field
--- @param name string|nil The field name
--- @param fields Field[] The fields contained in the table
--- @return Table @The new Table field
function Table.New(name, fields, ignoreNames)
    --- @class (partial) Table
    local o = setmetatable(Field.New(name, TABLE), Table)

    o.fields = fields
    o.ignoreNames = ignoreNames

    return o
end

--- Handles a table of values
--- @param data table The table data to handle
--- @return string|nil @The binary string representation, or nil on error
function Table:Serialize(data)
    local result = ''

    if not assert(type(data) == 'table', 'Value must be a table.') then
        return
    end

    for i, field in ipairs(self.fields) do
        result = result .. field:Serialize(data[i])
    end

    return result
end

function Table:Unserialize(dataBuffer)
    local result = {}

    local field, unserializedData
    for i = #self.fields, 1, -1 do
        field = self.fields[i]

        unserializedData = field:Unserialize(dataBuffer)

        if not field.name or self.ignoreNames then
            table.insert(result, 1, unserializedData)
        else
            result[field.name] = unserializedData
        end
    end

    return result
end

-- ----------------------------------------------------------------------------

--- @class Boolean : Field
--- @field __index Boolean
-- - @field fullBitLength integer The full bit length of boolean field
local Boolean = setmetatable({}, { __index = Field })
Boolean.__index = Boolean

--- Creates a new Boolean field
--- @param name string|nil The field name
--- @return Boolean @The new Boolean field
function Boolean.New(name)
    --- @class (partial) Boolean
    local o = setmetatable(Field.New(name, BOOLEAN), Boolean)

    return o
end

--- Handles a boolean value
--- @param data boolean The boolean data to handle
--- @return string|nil The binary string representation, or nil on error
function Boolean:Serialize(data)
    if not assert(type(data) == 'boolean', 'Value must be a boolean.') then
        return
    end

    return data and '1' or '0'
end

function Boolean:Unserialize(dataBuffer)
    local data = dataBuffer:Read(1)
    return data == '1'
end

-- ----------------------------------------------------------------------------

--- @class String : Field
--- @field __index String
-- @field fullBitLength integer The full bit length of boolean field
local String = setmetatable({}, { __index = Field })
String.__index = String

--- Creates a new Boolean field
--- @param name string|nil The field name
--- @return String @The new String field
function String.New(name, maxLength)
    --- @class (partial) String
    local o = setmetatable(Field.New(name, STRING), String)

    local lengthBits = math.ceil(math.log(maxLength) / math.log(2))
    o.length = Numeric.New(nil, lengthBits)

    return o
end

--- Handles a string value
--- @param data string The string data to handle
--- @return string|nil The binary string representation, or nil on error
function String:Serialize(data)
    if not assert(type(data) == 'string', 'Value must be a string.') then
        return
    end

    local result = self.length:Serialize(#data)

    Log('Serializing the string %s of length %d, serializedLength: %s', data, #data, result)
    for i = 1, #data do
        local byte = data:byte(i)
        local binaryByte = decimalToBinaryString(byte, 8)
        result = binaryByte .. result
    end

    return result
end

function String:Unserialize(dataBuffer)
    local result = ''

    local bytesTotal = self.length:Unserialize(dataBuffer)

    Log('Unserializing the string of bytes length %d', bytesTotal)

    local bytesRead = 0
    while bytesRead < bytesTotal do
        local firstByte = binaryStringToDecimal(dataBuffer:Read(8))

        local numBytes = 1
        if firstByte >= 0xC0 and firstByte < 0xE0 then
            numBytes = 2
        elseif firstByte >= 0xE0 and firstByte < 0xF0 then
            numBytes = 3
        elseif firstByte >= 0xF0 then
            numBytes = 4
        end

        local bytes = {firstByte}
        for j = 2, numBytes do
            bytes[j] = binaryStringToDecimal(dataBuffer:Read(8))
        end

        result = result .. string.char(unpack(bytes))
        bytesRead = bytesRead + #bytes
    end

    return result
end

-- ----------------------------------------------------------------------------

lib.Base = {
    Custom = Base.FromAlphabet,
    Base64RCF4648 = Base64RCF4648,
    Base64LinkSafe = Base64LinkSafe,
    Base256LibBinaryEncode = {
        Encode = LBE.Encode,
        Decode = LBE.DecodeToString,
    },
}

lib.Field = {
    Number = Numeric.New,
    Array = Array.New,
    Table = Table.New,
    Bool = Boolean.New,
    String = String.New,
}

function lib.Pack(data, schema, base)
    Log('Packing data with base ', tostring(base))
    base = base or Base64LinkSafe
    return base:Encode(schema:Serialize(data))
end

function lib.Unpack(data, schema, base)
    base = base or Base64LinkSafe
    return schema:Unserialize(Buffer.New(base:Decode(data)))
end

-- ----------------------------------------------------------------------------

LibDataPacker = lib