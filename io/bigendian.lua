local io = require ((...):gsub("%.[^%.]+$", ""))
local be = {}

function be.hasvalue()
    return false
end

function be.width(n)
    assert(n == nil, "'>' is an endianness control, and does not have width")
    return 0
end

function be.unpack()
    io("endianness", "big")
end

be.pack = be.unpack

return be
