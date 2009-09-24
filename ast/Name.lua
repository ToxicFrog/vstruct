return function(key, value)
    local Name = {
        tag = "name";
        width = value.width;
        key = key;
        value = value;
    }
    
    function Name:show()
        io.write("name\t"..key.."\t")
        value:show()
    end
    
    function Name:unpack(fd, buf, data)
        data[key] = value:unpack(fd, buf, data)
    end
    
    return Name
end
