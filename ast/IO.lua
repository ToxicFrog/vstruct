local io = require ((...):gsub("ast%.IO$", "io"))

return function(name, width)
    width = tonumber(width.text)
    
    -- FIXME validate width
    -- io("validate", name, width)
    
    local IO = {
        tag = "io";
        width = width;
        type = name;
    }
    
    function IO:show()
        print("io", name, width)
    end
    
    function IO:unpack(fd, buf, data)
        return io(name, "unpack", fd, buf, data)
--        return "<<%s %d>>" % name % width
    end
    
    return IO
end
