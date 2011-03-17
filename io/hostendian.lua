-- = set endianness to same as host system

local io = require "vstruct.io"
local he = {}

function he.hasvalue()
    return false
end

function he.width(n)
    assert(n == nil, "'=' is an endianness control, and does not have width")
    return 0
end

function he.unpack()
    io("endianness", "host")
end

he.pack = he.unpack

return he
