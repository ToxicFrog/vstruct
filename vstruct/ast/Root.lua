local io = require "vstruct.io"
local Node = require "vstruct.ast.Node"

local Root = Node:copy()

function Root:__init(children)
  self[1] = children
end

function Root:execute(fd, data, env)
  env.initialize(fd, data, env)
  self[1]:execute(env)
  return env.finalize()
end

function Root:read(fd, data)
  io("endianness", "host")
  self[1]:read(fd, data)
  return data
end
  
return Root
