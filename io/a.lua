-- align-to

local io = require "vstruct.io"
local a = {}

function a.hasvalue()
    return false
end

function a.width()
    return nil
end

function a.unpack(fd, _, align)
    local cur = fd:seek()
    
    if cur % align ~= 0 then
        fd:seek("cur", align - (cur % align))
    end
end

a.pack = a.unpack

return a
