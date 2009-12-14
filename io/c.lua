local io = require ((...):gsub("%.[^%.]+$", ""))
local c = {}

function c.width(n)
    return nil,tonumber(n)
end

function c.unpack(fd, _, _, width)
    assert(width)
    local buf = fd:read(width)
    return fd:read(io("u", "unpack", nil, buf, width))
end

function c.pack(fd, data, _, width)
    return io("u", "pack", nil, #data, width)
        .. io("s", "pack", nil, data)
end

return c
