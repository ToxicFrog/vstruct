return function(count, value)
    local Repeat = {
        tag = "repeat";
        width = (value.width and count * value.width) or nil;
        len = (count * value.len);
        count = count;
        value = value;
    }
    
    function Repeat:show()
        io.write("repeat\t"..tostring(count).."\t")
        value:show()
    end
    
    function Repeat:unpack(fd, buf, data)
        for i=1,count do
            local val = value:unpack(fd, buf, data)
            if val then
                data[#data+1] = val
            end
        end
    end
   
    function Repeat:pack(fd, data, key)
        local buf = {}
        for i=1,count do
            buf[#buf+1] = value:pack(fd, data, key)
            key = key + value.len
        end
        return table.concat(buf)
    end
    
    return Repeat
end
