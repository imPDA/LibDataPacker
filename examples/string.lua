local Log = LibDataPacker_Logger()

local LDP = LibDataPacker
LDP.examples = LDP.examples or {}
LDP.examples.String = {}

local example = LDP.examples.String

-- ----------------------------------------------------------------------------

local function stringExample()
    local Field = LDP.Field

    local schema = Field.Array(nil, 5, Field.String(nil, 50))

    local data = {
        '@SomeRandomId',
        '@ÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆ',
        '@SUPERPLÅYERPK',
        '@PlayerKillerPK',
        '@こんにちは',
    }

    -- concatenated
    --  "@SomeRandomId@ÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆ@SUPERPLÅYERPK@PlayerKillerPK@こんにちは"
    -- 70 characters 102 bytes

    -- base64
    -- "R2Mw0XP!0XPw0SPw01Pw0@*26ct7gwDF,WL&8qDF9cH]2{cf3fVW37X5hjg7F7cHT4{#8Pt15q<#8Pt15q<#8Pt15q<#8Pt15q<#8Pt15q<#8Pt15q<#8Pt15qj5RX]gqDFfj!V;qTD6m"
    -- 141 characters, 141 bytes

    -- base256
    -- "dImodnaRemoS@6ńĞńĞńĞńĞńĞńĞńĞńĞńĞńĞńĞńĞńĞńĞńĞńĞńĞńĞńĞńĞńĝĄ´µć$UЖ\4Åć$UćU4ąÒÔŌЗ[ńŃRÜЗ^X[İĤğУŞã¡Şã«ŞãБşãБŞã@@2"
    -- 107 characters, 184 bytes

    example.data = data
    example.concatenated = table.concat(data, '')
    example.concatenatedLength = #example.concatenated
    Log('Concatenated: %s', example.concatenated)

    example.base64string = LDP.Pack(data, schema)
    example.base64length = #example.base64string
    Log('Base64 string: %s', example.base64string)

    example.base256string = LDP.Pack(data, schema, LDP.Base.Base256LibBinaryEncode)
    example.base256length = #example.base256string
    Log('Base256 string: %s', example.base256string)

    example.unpackedData1 = LDP.Unpack(example.base64string, schema)
    example.unpackedData2 = LDP.Unpack(example.base256string, schema, LDP.Base.Base256LibBinaryEncode)

    if Zgoo then
        Zgoo.CommandHandler('LibDataPacker.examples.String')
    end
end

example.run = stringExample