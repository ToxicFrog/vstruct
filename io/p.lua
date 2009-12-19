local io = require ((...):gsub("%.[^%.]+$", ""))

local p = {}

function p.width(int, frac)
    assert( (int+frac) % 8 == 0, "fixed point number is not byte-aligned")
    
    return (int+frac)/8
end

function p.unpack(fd, buf, int, frac)
    int = tonumber(int)
    frac = tonumber(frac)

    return io("i", "unpack", fd, buf, (int+frac)/8)/(2^frac)
end

function p.pack(fd, data, int, frac)
    int = tonumber(int)
    frac = tonumber(frac)
    
    return io("i", "pack", fd, data * 2^frac, (int+frac)/8)
end

return p
