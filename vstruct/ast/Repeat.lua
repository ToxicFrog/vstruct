return function(count, value)
    local Repeat = {
        tag = "repeat";
        width = (value.width and count * value.width) or nil;
        count = count;
        value = value;
    }
    
    function Repeat:show()
        io.write("repeat\t"..tostring(count).."\t")
        value:show()
    end
    
    function Repeat:gen(generator)
        if count > 0 then
            generator:startloop(count)
            value:gen(generator)
            generator:endloop(count)
        end
    end
    
    return Repeat
end
