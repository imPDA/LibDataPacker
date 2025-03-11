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

    local function genarateCoordinatesExample(type, amount, precision)
        local data = {}
        for i = 1, amount do
            data[i] = generateRandomCoordinate(precision)
        end

        local schema = Field.Array(nil, amount, type)
        local packedString = LDP.Pack(data, schema)
        local unpackedData = LDP.Unpack(packedString, schema)

        return {
            data = data,
            packedString = packedString,
            stringLength = #packedString,
            unpackedData = unpackedData,
            equal = equals(data, unpackedData),
        }
    end

    LDP.examples.Coordinates.exactCoordinates = genarateCoordinatesExample(EXACT, 35, 6)
    LDP.examples.Coordinates.approximateCoordinates = genarateCoordinatesExample(APPROXIMATE, 70, 3)

    if Zgoo then
        Zgoo.CommandHandler('LibDataPacker.examples.Coordinates')
    end
end

LDP.examples.Coordinates.run = coordinatesExample