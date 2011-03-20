local List = require "vstruct.ast.List"

local WRAPPER = {}

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
        local function wrapdata(t)
            local key = nil
            local n = 1
            
            local function next()
                local v
                if key ~= nil then
                    v,key = t[key],nil
                else
                    v,n = t[n],n+1
                end
                return v
            end
            
            local function setkey(self, newkey)
                key = newkey
            end
            
            return setmetatable({ next=next, key=setkey }, WRAPPER)
        end
        
        if getmetatable(data) == WRAPPER then
            return self.list:pack(fd, wrapdata(data:next()), key)
        else
            return self.list:pack(fd, wrapdata(data), key)
        end
    end
    
    function Table:gen(generator)
        generator:starttable()
        self.list:gen(generator)
        generator:endtable()
    end
    
    return Table
end

