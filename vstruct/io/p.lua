-- fixed point
-- format is pINTEGER_WIDTH,FRACTIONAL_WIDTH
-- widths are in *bits* even when operating in byte mode!
-- FIXME: this should support bitpacks

local io = require "vstruct.io"
local p = {}

function p.width(width, frac)
    assert(width*8 >= frac, "fixed point number has more fractional bits than total bits")
    
    return width
end

function p.unpack(fd, buf, width, frac)
    return io("i", "unpack", fd, buf, width)/(2^frac)
end

function p.pack(fd, data, width, frac)
    return io("i", "pack", fd, data * 2^frac, width)
end

return p
