-- skip/pad
-- unlike the seek controls @+- or the alignment control a, x will never call
-- seek, and instead uses write '\0' or read-and-ignore - this means it is
-- safe to use on streams.

local io = require "vstruct.io"
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
