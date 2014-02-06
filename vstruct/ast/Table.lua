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
  
  return Table
end

