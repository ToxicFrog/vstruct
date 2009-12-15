return function()
    local List = {
        tag = "list";
        width = 0;
    }
    local child
    
    function List:append(node)
        if node.width then
            if not child then
                child = {
                    tag = "sublist";
                    width = 0;
                    show = self.show;
                    unpack = self.unpack;
                    pack = self.pack;
                    gen = self.gen;
                }
                self[#self+1] = child
            end
            
            if self.width then
                self.width = self.width + node.width
            end
            
            child[#child+1] = node
            child.width = child.width + node.width
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
    
    function List:gen(generator)
        if self.width then
            generator:readahead(self.width)
        end
        for i,v in ipairs(self) do
            v:gen(generator)
        end
        if self.width then
            generator:readahead(nil)
        end
    end
    
    return List
end
