-- signed integers

local io = require "vstruct.io"
local i = {}

function i.unpack(fd, buf, width)
    local n = io("u", "unpack", fd, buf, width)

    if n >= 2^(width*8-1) then
        return n - 2^(width*8)
    end
    
    return n
end

function i.unpackbits(bit, width)
    local n = io("u", "unpackbits", bit, width)
    
    if n >= 2^(width-1) then
        return n - 2^width
    end
    
    return n
end

function i.pack(_, data, width)
    if data < 0 then
        data = data + 2^(width*8)
    end
    
    return io("u", "pack", _, data, width)
end

function i.packbits(bit, data, width)
    if data < 0 then
        data = data + 2^width
    end
    
    return io("u", "packbits", bit, data, width)
end

return i
