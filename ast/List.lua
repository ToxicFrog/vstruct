return function()
    local List = {
        tag = "list";
        width = 0;
        len = 0;
    }
    local child
    
    function List:append(node)
        self.len = self.len + node.len
        if node.width then
            if not child then
                child = {
                    tag = "sublist";
                    width = 0;
                    len = 0;
                    show = self.show;
                    unpack = self.unpack;
                    pack = self.pack;
                }
                self[#self+1] = child
            end
            
            if self.width then
                self.width = self.width + node.width
            end
            
            child[#child+1] = node
            child.width = child.width + node.width
            child.len = child.len + node.len
        else
            child = nil
            self.width = nil
            self[#self+1] = node
        end
    end
    
    function List:show(data)
        for i,node in ipairs(self) do
            if node.show then
                node:show()
            end
        end
    end
    
    function List:unpack(fd, buf, data)
        for i,v in ipairs(self) do
            local val
            
            -- can't determine width of this subtree ahead of time
            if not v.width then
                val = v:unpack(fd, nil, data)
                
            -- can
            else
                -- were we passed a buffer to unpack from? if so, pass the first
                -- (child-width) bytes from the buffer in, and advance the
                -- buffer
                if buf then
                    val = v:unpack(fd, buf:sub(1, v.width), data)
                    buf = buf:sub(v.width + 1, -1)
                
                -- if not, read the next (child-width) bytes from the fd and
                -- pass that
                else
                    val = v:unpack(fd, fd:read(v.width), data)
                end
            end

            if val ~= nil then
                data[#data+1] = val
            end
        end
    end
    
    function List:pack(fd, data, key)
        local buf = {}
        
        for i,v in ipairs(self) do
            buf[#buf+1] = v:pack(fd, data, key)
            key = key + v.len
        end
        return table.concat(buf)
    end

    return List
end
