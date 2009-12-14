local io = require ((...):gsub("ast%.IO$", "io"))

return function(name, width)
    local args = { select(2, io(name, "width", width)) }
    width = io(name, "width", width)
    
    
    local IO = {
        tag = "io";
        width = width;
        len = io(name, "hasvalue") and 1 or 0;
        args = args;
        type = name;
    }
    
    function IO:show()
        print("io", name, width)
    end
    
    function IO:unpack(fd, buf)
        return io(name, "unpack", fd, buf, width, unpack(args))
    end
    
    function IO:pack(fd, data, key)
        --print("IO-pack", data, key, data[key], "!!", unpack(data))
        return io(name, "pack", fd, data[key], width, unpack(args))
    end
    
    return IO
end
