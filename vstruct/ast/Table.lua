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
  
  function Table:execute(env)
    env.push()
    self.list:execute(env)
    env.pop()
  end

  function Table:read(fd, data)
    local t = {}
    self.list:read(fd, t)
    return t
  end

  function Table:readbits(bits, data)
    local t = {}
    self.list:readbits(bits, t)
    return t
  end 
  
  return Table
end

