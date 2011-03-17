-- boolean

local io = require "vstruct.io"
local b = {}

function b.unpack(_, buf)
    return (buf:match("%Z") and true) or false
end

function b.unpackbits(bit, width)
    local n = 0
    for i=1,width do
        n = n + bit()
    end
    return n > 0
end

function b.pack(_, data, width)
    return io("u", "pack", nil, data and 1 or 0, width)
end

function b.packbits(bit, data, width)
    for i=1,width do
        bit(data and 1 or 0)
    end
end

return b
