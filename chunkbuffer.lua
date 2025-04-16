local floor = math.floor

-- ----------------------------------------------------------------------------

local ChunkBuffer = {}
ChunkBuffer.__index = ChunkBuffer

function ChunkBuffer.New(tbl, chunkSize)
    local self = setmetatable(tbl or {}, ChunkBuffer)

    self.chunkSize = chunkSize

    self.chunkPointer = 1
    self.shift = 0

    return self
end

function ChunkBuffer:GetPointers(position)
    return floor(position / self.chunkSize) + 1, position % self.chunkSize
end

function ChunkBuffer:Seek(position)
    self.chunkPointer = floor(position / self.chunkSize) + 1
    self.shift = position % self.chunkSize
end

function ChunkBuffer:Skip(length)
    length = length + self.shift
    self.chunkPointer = self.chunkPointer + floor(length / self.chunkSize)
    self.shift = length % self.chunkSize
end

local MBL = {}
do
    for i = 1, 32 do MBL[i] = 2^i - 1 end
end

function ChunkBuffer:Read(length)
    local startBytePointer, startShiftPointer = self.chunkPointer, self.shift
    self:Skip(length)
    local newBytePointer, newShiftPointer = self.chunkPointer, self.shift

    local decimal = BitAnd(self[newBytePointer], MBL[newShiftPointer])

    local C = self.chunkSize

    for i = newBytePointer - 1, startBytePointer, -1  do
        decimal = BitOr(BitLShift(decimal, C), self[i])
    end

    return BitRShift(decimal, startShiftPointer)
end

function ChunkBuffer:Write(decimal, length)
    if MBL[length] < decimal then
        error(('%d cant be written to buffer with length %d'):format(decimal, length))
    end

    local C = self.chunkSize
    local L = 2^C-1

    decimal = BitLShift(decimal, self.shift)

    local startBytepointer = self.chunkPointer
    self:Skip(length)
    local newBytePointer = self.chunkPointer

    for i = startBytepointer, newBytePointer do
        self[i] = BitOr(BitAnd(decimal, L), self[i])
        decimal = BitRShift(decimal, C)
    end
end

-- TODO: optimize
function ChunkBuffer:WriteBit(bit)
    self:Write(bit, 1)
end

function ChunkBuffer:Available()
    return self.chunkPointer <= #self
end

-- ----------------------------------------------------------------------------

LibDataPacker_BinaryBuffer = ChunkBuffer
