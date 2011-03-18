local io = require "vstruct.io"

local function argv2str(argv)
    local args = {}
    
    for i,v in ipairs(argv) do
        args[i] = tostring(v)
    end
    
    return table.concat(args, ", ")
end

return function(name, args)
    local argv = { n = 0 }
    
    if args then
        local args = args..","
        local n = 1
        
        for arg in args:gmatch("([^,]*),") do
            if #arg == 0 then arg = "nil" end
            argv.n = argv.n +1
            argv[argv.n] = arg
        end
    end
    
    local width = io(name, "width", unpack(argv, 1, argv.n))
    
    local IO = {
        tag = "io";
        width = width;
    }
    
    function IO:show()
        print("io", name, width)
    end
    
    function IO:gen(generator)
        generator:io(name, io(name, "hasvalue"), width, argv.n > 0 and argv2str(argv))
    end
    
    return IO
end
