return function(key, value)
    local Name = {
        tag = "name";
        width = value.width;
        len = 0;
        key = key;
        value = value;
    }
    
    function Name:show()
        io.write("name\t"..key.."\t")
        value:show()
    end
    
    function Name:unpack(fd, buf, data)
        local v = value:unpack(fd, buf, data)
        
        if v == nil then
            error("vstruct: sanity failure: named field unpacked to nil\nmake sure you haven't given a name to a seek command or similar")
        end
        
        data[key] = v 
    end
    
    function Name:pack(fd, data)
        -- HACK HACK HACK
        -- if the child is an IO node, pass it the key and table seperately, and
        -- it'll unpack it itself
        -- otherwise, extract the new source table and pass it down
        -- HACK HACK HACK
        if value.tag == "io" then
            value:pack(fd, data, key)
        else
            value:pack(fd, data[key], 1)
        end
    end
    
    return Name
end
