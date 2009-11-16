local io = require ((...):gsub("%.[^%.]+$", ""))
local i = {}

function i.unpack(fd, buf, width)
    local n = io("u", "unpack", fd, buf, width)

    if n >= 2^(width*8-1) then
        return n - 2^(width*8)
    end
    
    return n
end

function i.pack(_, data, width)
    if data < 0 then
        data = data + 2^(width*8)
    end
    
    return io("u", "pack", _, data, width)
end


return i
