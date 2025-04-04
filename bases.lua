-- local Log = LibDataPacker_Logger()
local BinaryBuffer = LibDataPacker_BinaryBuffer
local floor = math.floor
local log = math.log

-- ----------------------------------------------------------------------------

local function decimalToBinaryArray(decimal, length)
    if 2^length-1 < decimal then
        error(('%d cant be written to buffer with length %d'):format(decimal, length))
    end

    local array = {}
    for i = 1, length do
        array[i] = decimal % 2
        decimal = math.floor(decimal / 2)
    end

    return array
end

-- ----------------------------------------------------------------------------

--- @class Base
--- @field __index Base
--- @field alphabet table The alphabet to use
--- @field encodeTable table Encode table based on alphabet 
--- @field lookupTable table Lookup table based on alphabet 
--- @field bitLength integer Bit length of one charater from the alphabet
local Base = {}
Base.__index = Base

function Base.FromAlphabet(alphabet)
    local concreteBase = setmetatable({}, Base)

    local bitLength = floor(log(#alphabet+1) / log(2))
    local alphabetArray = { alphabet:byte(1, #alphabet) }

    local lookupTable = {}
    for i = 1, #alphabetArray do
        lookupTable[alphabetArray[i]] = decimalToBinaryArray(i - 1, bitLength)
    end

    concreteBase.bitLength = bitLength
    concreteBase.alphabet = alphabetArray
    concreteBase.lookupTable = lookupTable

    return concreteBase
end

function Base:Encode(binaryBuffer)
    local tempTable = {}
    BinaryBuffer.Seek(binaryBuffer, 0)

    local decimal
    local i = 1
    while BinaryBuffer.Available(binaryBuffer) do
        decimal = BinaryBuffer.Read(binaryBuffer, self.bitLength)
        tempTable[i] = self.alphabet[decimal+1]
        i = i + 1
    end

    return string.char(unpack(tempTable))
end

function Base:Decode(encodedString)
    local binaryBuffer = BinaryBuffer.New()

    local charsArray = { encodedString:byte(1, #encodedString) }
    for i = 1, #charsArray do
        BinaryBuffer.WriteBits(binaryBuffer, self.lookupTable[charsArray[i]])
    end
    BinaryBuffer.Seek(binaryBuffer, 0)

    return binaryBuffer
end

-- ----------------------------------------------------------------------------

local Base64RCF4648 = Base.FromAlphabet('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/')
local Base64LinkSafe = Base.FromAlphabet('23456789CFGHJMPQRVWXcfghjmpqrvwx01bBdDkKlLsStT!@#&=_{};,<>`~-]*/')

-- ----------------------------------------------------------------------------

local Base256LibBinaryEncode = LBE and {
    Encode = LBE.Encode,
    Decode = LBE.DecodeToString,
} or {
    __index = error('LibBinaryEncode is missing!')
}

-- ----------------------------------------------------------------------------
--[[
local char = string.char

--- @class PrimitiveBase
--- @field __index PrimitiveBase
--- @field bitLength integer Bit length of one character
local PrimitiveBase = {}
PrimitiveBase.__index = PrimitiveBase

function PrimitiveBase.New(bitLength)
    local concreteBase = setmetatable({}, PrimitiveBase)

    concreteBase.bitLength = bitLength

    return concreteBase
end

function PrimitiveBase:Encode(binaryString)
    local encodedString = ''

    local startIndex, dec, character
    for i = #binaryString, 1, -self.bitLength do
        startIndex = i - self.bitLength + 1
        startIndex = startIndex > 1 and startIndex or 1
        dec = binaryStringToDecimal(binaryString:sub(startIndex, i)) + 32
        encodedString = encodedString .. char(dec)
    end

    return encodedString
end

function PrimitiveBase:Decode(encodedString)
    local binaryString = ''

    local bytes = { encodedString:byte(1, #encodedString) }

    for _, byte in ipairs(bytes) do
        byte = byte - 32
		binaryString = decimalToBinaryString(byte, self.bitLength) .. binaryString
	end

    return binaryString
end
--]]

-- local Base128Primitive = PrimitiveBase.New(7)
-- local Base256Primitive = PrimitiveBase.New(8)

-- ----------------------------------------------------------------------------

local LDP = LibDataPacker

LDP.Base = {
    CustomAlphabet = Base.FromAlphabet,
    Base64RCF4648 = Base64RCF4648,
    Base64LinkSafe = Base64LinkSafe,
    Base256LibBinaryEncode = Base256LibBinaryEncode,
    -- Base128Primitive = Base128Primitive,
    -- Base256Primitive = Base256Primitive,
}
