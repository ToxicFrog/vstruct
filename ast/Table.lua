local List = require ((...):gsub("Table$", "List"))

return function()
    local Table = {
        tag = "table";
        list = List();
        value = {};
        width = 0;
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
        Table.list:unpack(fd, buf, Table.value)
        return Table.value
    end
    
    return Table
end

