-- fixed length strings

local io = require "vstruct.io"
local s = {}

function s.width(w)
    return tonumber(w)
end

function s.unpack(fd, buf, width)
    if width then
        assert(#buf == width, "sanity failure: length of buffer does not match length of string format")
        return buf
    end
    
    return fd:read('*a')
end

function s.pack(_, data, width)
    width = width or #data
    if width > #data then
        data = data..string.rep("\0", width - #data)
    end
    return data:sub(1,width)
end

return s
