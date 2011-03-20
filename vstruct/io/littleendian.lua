-- < set endianness: little

local io = require "vstruct.io"
local le = {}

function le.hasvalue()
    return false
end

function le.width(n)
    assert(n == nil, "'<' is an endianness control, and does not have width")
    return 0
end

function le.unpack()
    io("endianness", "little")
end

le.pack = le.unpack

return le
