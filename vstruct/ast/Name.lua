local Node = require "vstruct.ast.Node"
local Name = Node:copy()

local function put(data, key, val)
  if not key then
    data[#data+1] = val
  else
    local data = data
    for name in key:gmatch("([^%.]+)%.") do
      if data[name] == nil then
        data[name] = {}
      end
      data = data[name]
    end
    data[key:match("[^%.]+$")] = val
  end
end

function Name:__init(key, child)
  self.child = child
  self.size = child.size
  self.key = key
end
  
function Name:execute(env)
  env.name(self.key)
  self.child:execute(env)
end

function Name:read(fd, data)
  return put(data, self.key, self.child:read(fd, data))
end

function Name:readbits(bits, data)
  return put(data, self.key, self.child:readbits(bits, data))
end

return Name
