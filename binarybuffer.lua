local BinaryBuffer = {}
BinaryBuffer.__index = BinaryBuffer

function BinaryBuffer.New(tbl)
    local self = setmetatable(tbl or {}, BinaryBuffer)

    self.pointer = 0

    return self
end

function BinaryBuffer:Seek(position)
    self.pointer = position
end

function BinaryBuffer:Read(length)
    local decimal = 0

    local start = self.pointer + 1
    self.pointer = self.pointer + length
    local stop = math.min(#self, self.pointer)

    for i = stop, start, -1 do
        decimal = decimal * 2 + self[i]
    end

    return decimal
end

function BinaryBuffer:Write(decimal, length)
    if 2^length-1 < decimal then
        error(('%d cant be written to buffer with length %d'):format(decimal, length))
    end

    for i = 1, length do
        self[self.pointer+i] = decimal % 2
        decimal = math.floor(decimal / 2)
    end

    self.pointer = self.pointer + length
end

function BinaryBuffer:WriteBit(bit)
    self.pointer = self.pointer + 1
    self[self.pointer] = bit
end

function BinaryBuffer:WriteBits(bits, length)
    for i = 1, length do
        self[self.pointer+i] = bits[i]
    end

    self.pointer = self.pointer + length
end

function BinaryBuffer:Available()
    return self.pointer <= #self
end

-- ----------------------------------------------------------------------------

LibDataPacker_BinaryBuffer = BinaryBuffer
