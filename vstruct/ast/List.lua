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
          execute = self.execute;
          read = self.read;
          readbits = self.readbits;
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
  
  function List:execute(env)
    for i,child in ipairs(self) do
      child:execute(env)
    end
  end

  function List:read(fd, data)
    for i,child in ipairs(self) do
      child:read(fd, data)
    end
  end

  function List:readbits(bits, data)
    for i,child in ipairs(self) do
      child:readbits(bits, data)
    end
  end

  return List
end
