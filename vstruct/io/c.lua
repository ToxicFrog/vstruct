-- counted strings

local io = require "vstruct.io"
local c = {}

function c.width(n)
    return nil
end

function c.unpack(fd, _, width)
    assert(width)
    local buf = fd:read(width)
    local len = io("u", "unpack", nil, buf, width)
    if len == 0 then
        return ""
    end
    return fd:read(len)
end

function c.pack(fd, data, width)
    return io("u", "pack", nil, #data, width)
        .. io("s", "pack", nil, data)
end

return c
