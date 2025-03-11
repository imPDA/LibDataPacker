local Log = LibDataPacker_Logger()

local LDP = LibDataPacker
LDP.examples = LDP.examples or {}
LDP.examples.Common = {}

local example = LDP.examples.Common

-- ----------------------------------------------------------------------------

local function generaterandomStats()
    return {
        'SomeRandomId',
        math.random(2) == 2,
        math.floor(math.random() * 16770000),
        math.floor(math.random() * 16770000),
        math.floor(math.random() * 16770000),
        math.floor(math.random() * 2047),
    }
end

-- ----------------------------------------------------------------------------

local function commonExample()
    local Field = LDP.Field

    local IGNORE_NAMES = true

    local playerStats = Field.Table(nil, {
        Field.String('displayName', 50),
        Field.Bool('someFlag'),
        Field.Number('damageDone', 24),  -- ~16.77М max
        Field.Number('damageTaken', 24),
        Field.Number('healingDone', 24),
        Field.Number('durationSeconds', 11),  -- 2047 seconds or ~34 minutes max
    }, IGNORE_NAMES)

    local schema = Field.Array('groupStats', 12, playerStats)

    local data = {}
    for i = 1, 12 do
        data[#data+1] = generaterandomStats()
    end

    example.data = data

    example.base64string = LDP.Pack(data, schema)
    example.base64length = #example.base64string
    Log('Base64 string: %s', example.base64string)

    example.base256string = LDP.Pack(data, schema, LDP.Base.Base256LibBinaryEncode)
    example.base256length = #example.base256string
    Log('Base256 string: %s', example.base256string)

    example.unpackedData1 = LDP.Unpack(example.base64string, schema)
    example.unpackedData2 = LDP.Unpack(example.base256string, schema, LDP.Base.Base256LibBinaryEncode)

    if Zgoo then
        Zgoo.CommandHandler('LibDataPacker.examples.Common')
    end
end

example.run = commonExample