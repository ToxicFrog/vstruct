local io = require ((...):gsub("%.[^%.]+$", ""))

local p = {}

function p.width(int, frac)
    assert( (int+frac) % 8 == 0, "fixed point number is not byte-aligned")
    
    return int+frac
end

function p.unpack(...)
    return 0.0
end

function p.pack(...)
    return io("x", "pack", ...)
end

return p
