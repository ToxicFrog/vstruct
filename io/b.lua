local io = require ((...):gsub("%.[^%.]+$", ""))
local b = {}

function b.unpack(_, buf)
    return (buf:match("%Z") and true) or false
end

function b.pack(_, data, width)
    return io("u", "pack", nil, data and 1 or 0, width)
end

return b
