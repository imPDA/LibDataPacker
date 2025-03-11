local Log = LibDataPacker_Logger()

local LDP = LibDataPacker
LDP.examples = LDP.examples or {}
LDP.examples.Coordinates = {}

local function equals(array1, array2)
    local equalsFlag = true

    local c2
    for i, c1 in ipairs(array1) do
        c2 = array2[i]
        if c1[1] ~= c2[1] or c1[2] ~= c2[2] then
            Log('%d coordinate differs, 1: (%d, %d), 2: (%d, %d)', i, c1[1], c1[2], c2[1], c2[2])
            equalsFlag = false
        end
    end

    return equalsFlag
end

-- ----------------------------------------------------------------------------

local function coordinatesExample()
    local Field = LDP.Field

    local EXACT         = Field.Array('xy', 2, Field.Number(nil, 20))  -- from 0 to 0.999999
    local APPROXIMATE   = Field.Array('xy', 2, Field.Number(nil, 10))  -- from 0 to 0.999

    local function generateRandomCoordinate(precision)
        return {
            math.random(math.pow(10, precision)) - 1,
            math.random(math.pow(10, precision)) - 1,
        }
    end

    local exacts = {}

    local amountExactCoordinates = 35
    local exactCoordinatesScheme = Field.Array(nil, amountExactCoordinates, EXACT)

    local exactCoordinates = {}
    for i = 1, amountExactCoordinates do
        exactCoordinates[i] = generateRandomCoordinate(6)
    end
    exacts.data = exactCoordinates

    local exactCoordinatesString = LDP.Pack(exactCoordinates, exactCoordinatesScheme, LDP.Base.Base256LibBinaryEncode)
    exacts.string = exactCoordinatesString
    exacts.stringLength = #exactCoordinatesString
    Log('Exact coords string: %s', exactCoordinatesString)

    local exactCoordinatesUnpackedData = LDP.Unpack(exactCoordinatesString, exactCoordinatesScheme, LDP.Base.Base256LibBinaryEncode)
    exacts.unpackedData = exactCoordinatesUnpackedData

    exacts.equals = equals(exactCoordinates, exactCoordinatesUnpackedData, true)

    -- ------------------------------------------------------------------------

    local approximates = {}

    local amountApproximateCoordinates = 70
    local approximateCoordinatesScheme = Field.Array(nil, amountApproximateCoordinates, APPROXIMATE)

    local approximateCoordinates = {}
    for i = 1, amountApproximateCoordinates do
        approximateCoordinates[i] = generateRandomCoordinate(3)
    end
    approximates.data = approximateCoordinates

    local approximateCoordinatesString = LDP.Pack(approximateCoordinates, approximateCoordinatesScheme, LDP.Base.Base256LibBinaryEncode)
    approximates.string = approximateCoordinatesString
    approximates.stringLength = #approximateCoordinatesString

    Log('Approximate coords string: %s', approximateCoordinatesString)

    local approximateCoordinatesUnpackedData = LDP.Unpack(approximateCoordinatesString, approximateCoordinatesScheme, LDP.Base.Base256LibBinaryEncode)
    approximates.unpackedData = approximateCoordinatesUnpackedData

    approximates.equals = equals(approximateCoordinates, approximateCoordinatesUnpackedData, true)

    -- ------------------------------------------------------------------------

    LDP.examples.Coordinates.exactCoordinates = exacts
    LDP.examples.Coordinates.approximateCoordinates = approximates

    if Zgoo then
        Zgoo.CommandHandler('LibDataPacker.examples.Coordinates')
    end
end

LDP.examples.Coordinates.run = coordinatesExample