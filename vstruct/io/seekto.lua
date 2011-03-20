-- @ seek to a constant offset

local seek = {}

function seek.hasvalue()
    return false
end

function seek.width()
    return nil
end

function seek.unpack(fd, _, offset)
    fd:seek("set", offset)
end
seek.pack = seek.unpack

return seek
