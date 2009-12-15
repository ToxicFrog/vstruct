local io = require ((...):gsub("%.[^%.]+$", ""))

local f = {}

function f.unpack(...)
    return 0.0
end

function f.pack(...)
    return io("x", "pack", ...)
end

return f
