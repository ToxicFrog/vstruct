local io = require ((...):gsub("ast%.IO$", "io"))

return function(name, args)
    local argv = {}
    
    if args then
        for arg in args:gmatch("[^,]+") do
            argv[#argv+1] = arg
        end
    end
    
    local width = io(name, "width", unpack(argv))
    
    local IO = {
        tag = "io";
        width = width;
    }
    
    function IO:show()
        print("io", name, width)
    end
    
    function IO:gen(generator)
        generator:io(name, io(name, "hasvalue"), width, args)
    end
    
    
    return IO
end
