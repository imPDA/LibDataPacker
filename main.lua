-- local Log = LibDataPacker_Logger()
local BinaryBuffer = LibDataPacker_BinaryBuffer
local floor = math.floor
local ceil = math.ceil
local log = math.log

local lib = {}

-- ----------------------------------------------------------------------------

local function maxBitLengthFor(number)
    return ceil(log(number + 1) / log(2))
end

-- ----------------------------------------------------------------------------

local EMPTY = 0
local NUMERIC = 1
local TABLE = 2
local ARRAY = 3
local BOOLEAN = 4
local STRING = 5
local ENUM = 6
local VARIABLE_LENGTH_ARRAY = 7
local OPTIONAL = 8

-- ----------------------------------------------------------------------------

--- @class Field
--- @field __index Field
--- @field name string|nil The field name
--- @field fieldType integer The field type (EMPTY, NUMERIC, TABLE, ARRAY)
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

function Field:Serialize(data, buffer)
    assert(false, 'Must be overridden')
end

function Field:Unserialize(data)
    assert(false, 'Must be overridden')
end

-- ----------------------------------------------------------------------------

--- @class Numeric : Field
--- @field __index Numeric
--- @field bitLength integer The bit length for the numeric field
local Numeric = setmetatable({}, { __index = Field })
Numeric.__index = Numeric

--- @class NumericWithPrecision : Field
--- @field __index NumericWithPrecision
--- @field bitLength integer The bit length for the numeric field
--- @field mult number Multiplier
local NumericWithPrecision = setmetatable({}, { __index = Field })
NumericWithPrecision.__index = NumericWithPrecision

--- Creates a new Numeric field
--- @param name string|nil The field name
--- @param bitLength integer The bit length for the numeric field
--- @param precision integer|nil
--- @return Numeric|NumericWithPrecision @The new Numeric field
function Numeric.New(name, bitLength, precision)
    --- @class (partial) Numeric
    local o = Field.New(name, NUMERIC)
    o.bitLength = bitLength

    if precision and type(precision) == 'number' and precision ~= 0 then
        setmetatable(o, NumericWithPrecision)
        o.mult = 10^precision
    else
        setmetatable(o, Numeric)
    end

    return o
end

--- Handles a numeric value
--- @param data number The numeric data to handle
--- @return string|nil The binary string representation, or nil on error
function Numeric:Serialize(data, binaryBuffer)
    if not assert(type(data) == 'number', ('Value must be a number, got %s: %s'):format(type(data), tostring(data))) then
        return
    end

    binaryBuffer:Write(data, self.bitLength)
end

function Numeric:Unserialize(binaryBuffer)
    -- TODO: length check
    return binaryBuffer:Read(self.bitLength)
end

local function transformForward(number, mult)
    return floor(number * mult + 0.5)
end

--- Handles a numeric value
--- @param data number The numeric data to handle
--- @return string|nil The binary string representation, or nil on error
function NumericWithPrecision:Serialize(data, binaryBuffer)
    if not assert(type(data) == 'number', ('Value must be a number, got %s: %s'):format(type(data), tostring(data))) then
        return
    end

    binaryBuffer:Write(transformForward(data, self.mult), self.bitLength)
end

local function transformBackward(number, mult)
    return number / mult
end

function NumericWithPrecision:Unserialize(binaryBuffer)
    -- TODO: length check
    return transformBackward(binaryBuffer:Read(self.bitLength), self.mult)
end

-- ----------------------------------------------------------------------------

--- @class Array : Field
--- @field __index Array
--- @field length integer The array length
--- @field subType Field The field type for array elements
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

    return o
end

--- Handles an array of values
--- @param data table The array data to handle
--- @return string|nil The binary string representation, or nil on error
function Array:Serialize(data, binaryBuffer)
    if not assert(type(data) == 'table', 'Value must be a table.') then
        return
    end

    for _, datum in ipairs(data) do
        self.subType:Serialize(datum, binaryBuffer)
    end
end

function Array:Unserialize(dataBuffer)
    local result = {}

    -- TODO: length check

    for i = 1, self.length do
        result[i] = self.subType:Unserialize(dataBuffer)
    end

    return result
end

-- ----------------------------------------------------------------------------

--- @class VLArray : Field
--- @field __index VLArray
--- @field maxLength integer The array max length
--- @field subType Field The field type for array elements
local VLArray = setmetatable({}, { __index = Field })
VLArray.__index = VLArray

--- Creates a new VLArray field
--- @param name string|nil The field name
--- @param maxLength integer The array max length
--- @param subtype Field The field type for array elements
--- @return VLArray The new Array field
function VLArray.New(name, maxLength, subtype)
    --- @class (partial) VLArray
    local o = setmetatable(Field.New(name, VARIABLE_LENGTH_ARRAY), VLArray)

    local bitLength = maxBitLengthFor(maxLength)
    o.length = Numeric.New(nil, bitLength)

    o.subType = subtype

    return o
end

--- Handles an array of values
--- @param data table The array data to handle
--- @return string|nil The binary string representation, or nil on error
function VLArray:Serialize(data, binaryBuffer)
    if not assert(type(data) == 'table', 'Value must be a table.') then
        return
    end

    self.length:Serialize(#data, binaryBuffer)

    for _, datum in ipairs(data) do
        self.subType:Serialize(datum, binaryBuffer)
    end
end

function VLArray:Unserialize(binaryBuffer)
    local result = {}

    -- TODO: length check

    local length = self.length:Unserialize(binaryBuffer)

    for i = 1, length do
        result[i] = self.subType:Unserialize(binaryBuffer)
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
function Table:Serialize(data, binaryBuffer)
    -- local result = ''

    if not assert(type(data) == 'table', 'Value must be a table.') then
        return
    end

    local datum
    for i, field in ipairs(self.fields) do
        if self.ignoreNames then
            datum = data[i]
        else
            datum = data[field.name]
        end
        field:Serialize(datum, binaryBuffer)
    end

    -- return result
end

function Table:Unserialize(dataBuffer)
    local result = {}

    local field, unserializedData
    for i = 1, #self.fields do
        field = self.fields[i]

        unserializedData = field:Unserialize(dataBuffer)

        if not field.name or self.ignoreNames then
            table.insert(result, unserializedData)
        else
            result[field.name] = unserializedData
        end
    end

    return result
end

-- ----------------------------------------------------------------------------

--- @class Boolean : Field
--- @field __index Boolean
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
function Boolean:Serialize(data, binaryBuffer)
    -- Log('data: %s', tostring(data))
    if not assert(type(data) == 'boolean', 'Value must be a boolean.') then
        return
    end

    binaryBuffer:WriteBit(data and 1 or 0)
end

function Boolean:Unserialize(dataBuffer)
    return dataBuffer:Read(1) == 1
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

    local lengthBits = maxBitLengthFor(maxLength)
    o.length = Numeric.New(nil, lengthBits)

    return o
end

--- Handles a string value
--- @param data string The string data to handle
--- @return string|nil The binary string representation, or nil on error
function String:Serialize(data, binaryBuffer)
    if not assert(type(data) == 'string', 'Value must be a string.') then
        return
    end

    self.length:Serialize(#data, binaryBuffer)

    for i = 1, #data do
        local byte = data:byte(i)
        binaryBuffer:Write(byte, 8)
    end
end

function String:Unserialize(dataBuffer)
    local bytesTotal = self.length:Unserialize(dataBuffer)

    local bytesRead = 0
    local tempTable, i = {}, 1
    while bytesRead < bytesTotal do
        local firstByte = dataBuffer:Read(8)

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
            bytes[j] = dataBuffer:Read(8)
        end

        tempTable[i] = string.char(unpack(bytes))
        i = i + 1
        bytesRead = bytesRead + #bytes
    end

    return table.concat(tempTable)
end

-- ----------------------------------------------------------------------------

--- @class Enum : Field
--- @field __index Enum
local Enum = setmetatable({}, { __index = Field })
Enum.__index = Enum

--- Creates a new Enum field
--- @param name string|nil The field name
--- @param enumTable table The table of values
--- @param inverted boolean|nil If the table is lookup table instead
--- @return Enum @The new Enum field
function Enum.New(name, enumTable, inverted)
    --- @class (partial) Enum
    local o = setmetatable(Field.New(name, ENUM), Enum)

    o.forward = enumTable

    o.backward = {}
    for k, v in pairs(enumTable) do
        o.backward[v] = k
    end

    if inverted then
        o.forward, o.backward = o.backward, o.forward
    end

    local bitLength = maxBitLengthFor(#o.backward)
    o.subType = Numeric.New(nil, bitLength)

    return o
end

--- Handles a boolean value
--- @param data any The data to handle
--- @return string|nil The binary string representation, or nil on error
function Enum:Serialize(data, binaryBuffer)
    local newValue = self.forward[data]

    if newValue == nil then
        error(('Value %s is not found in enum table'):format(tostring(data)))
    end

    self.subType:Serialize(newValue, binaryBuffer)
end

function Enum:Unserialize(dataBuffer)
    local result = self.subType:Unserialize(dataBuffer)
    local newResult = self.backward[result]

    if newResult == nil then
        error(('Value %s not found in lookup table'):format(tostring(result)))
    end

    return newResult
end

-- ----------------------------------------------------------------------------

--- @class Optional : Field
--- @field __index Optional
--- @field subfield Field Subfield
local Optional = setmetatable({}, { __index = Field })
Optional.__index = Optional

--- Creates a new Optional field
--- @param subfield Field The subfield
--- @return Optional @The new Optional field
function Optional.New(subfield)
    --- @class (partial) Optional
    local o = setmetatable(Field.New(subfield.name, OPTIONAL), Optional)

    o.subfield = subfield

    return o
end

--- Handles a data
--- @param data any The field data to handle
--- @return string|nil The binary string representation, or nil on error
function Optional:Serialize(data, binaryBuffer)
    binaryBuffer:WriteBit(data == nil and 0 or 1)

    if data ~= nil then
        self.subfield:Serialize(data, binaryBuffer)
    end
end

function Optional:Unserialize(dataBuffer)
    if dataBuffer:Read(1) == 0 then return end

    return self.subfield:Unserialize(dataBuffer)
end

-- ----------------------------------------------------------------------------

--[[
--- @class EnumDecorator
--- @field __index EnumDecorator
local EnumDecorator = {}
EnumDecorator.__index = EnumDecorator

--- Creates a new Enum field
--- @param enumTable table Lookup table
--- @return EnumDecorator @The new Enum field
function EnumDecorator.New(enumTable, inverted)
    --- @class (partial) EnumDecorator
    local o = setmetatable({}, EnumDecorator)

    o.forward = enumTable

    o.backward = {}
    for k, v in pairs(enumTable) do
        o.backward[v] = k
    end

    if inverted then
        o.forward, o.backward = o.backward, o.forward
    end

    return o
end

--- Handles a enum value
--- @param field Field The field to decorate
--- @return Field @Decorated field
function EnumDecorator.__call(self, field)
    Log('Serializing Enum')
    if field.fieldType == TABLE then
        Log('Table, skipping')
        return field
    end

    local originalSerialize = field.Serialize
    field.Serialize = function(_self, data)
        Log('Data: %s', table.concat(data, ', '))
        local newData = {}
        for k, v in pairs(data) do
            newData[k] = self.forward[v]
        end
        Log('New data: %s', table.concat(newData, ', '))

        Log('Original field type: %s', field.fieldType)
        local result = originalSerialize(_self, newData)
        Log('Result: %s', tostring(result))

        return result
    end

    local originalUnserialize = field.Unserialize
    field.Unserialize = function(_self, data)
        local originalReturn = originalUnserialize(_self, data)

        local newReturn = {}
        for k, v in pairs(originalReturn) do
            newReturn[k] = self.backward[v]
        end

        return newReturn
    end

    return field
end
]]

-- ----------------------------------------------------------------------------

lib.Field = {
    Number = Numeric.New,
    Array = Array.New,
    VLArray = VLArray.New,
    Table = Table.New,
    Bool = Boolean.New,
    String = String.New,
    Enum = Enum.New,
    Optional = Optional.New,
}

function lib.Pack(data, schema, base)
    base = base or lib.Base.Base64RCF4648

    local binaryBuffer = BinaryBuffer.New()
    schema:Serialize(data, binaryBuffer)

    return base:Encode(binaryBuffer)
end

function lib.Unpack(data, schema, base)
    base = base or lib.Base.Base64RCF4648
    return schema:Unserialize(base:Decode(data))
end

-- ----------------------------------------------------------------------------

LibDataPacker = lib
