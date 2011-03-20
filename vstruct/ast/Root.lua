return function(child)
    local Root = {}
    
    function Root:gen(generator)
        generator:init()
        child:gen(generator)
        return generator:finalize()
    end
    
    function Root:append(...)
        return child:append(...)
    end
    
    function Root:show()
        return child:show()
    end
    
    return Root
end
