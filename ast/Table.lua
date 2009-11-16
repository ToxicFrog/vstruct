local List = require ((...):gsub("Table$", "List"))

return function()
    local Table = {
        tag = "table";
        list = List();
    }
    
    setmetatable(Table, { __index = Table.list })
    
    function Table:append(...)
        return Table.list:append(...)
    end
    
    function Table:show()
        print("table", Table.width, #Table.list)
        self.list:show()
    end
    
    function Table:unpack(fd, buf, data)
        local value = {}
        self.list:unpack(fd, buf, value)
        return value
    end
    
    function Table:pack(fd, data, key)
        return self.list:pack(fd, data, key)
    end
    
    return Table
end

