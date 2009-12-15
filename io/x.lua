local io = require ((...):gsub("%.[^%.]+$", ""))
local x = {}

function x.hasvalue()
    return false
end

function x.unpack(fd, buf, width)
    io("s", "unpack", fd, buf, width)
    return nil
end

function x.unpackbits(bit, width)
    for i=1,width do
        bit()
    end
end

function x.packbits(bit, _, width)
    for i=1,width do
        bit(0)
    end
end

function x.pack(fd, data, width)
    return string.rep("\0", width)
end

return x
