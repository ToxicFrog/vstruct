local io = require "vstruct.io"
local unpack = table.unpack or unpack
local Node = require "vstruct.ast.Node"
local IO = Node:copy()

local function str2args(args)
  local argv = { n = 0 }
  if args then
    local args = args..","
    
    for arg in args:gmatch("([^,]*),") do
      if #arg == 0 then arg = nil
      elseif tonumber(arg) then arg = tonumber(arg)
      end
      argv.n = argv.n +1
      argv[argv.n] = arg
    end
  end
  return argv
end

function IO:__init(name, args)
  self.name = name
  self.argv = str2args(args)

  if args then
  end

  self.size = io(name, "size", unpack(self.argv, 1, self.argv.n))
end
  
function IO:execute(env)
  local hasvalue = io(self.name, "hasvalue")
  local fn = env._bitpack and "bpio" or "io"

  if self.size and not env._bitpack then
    env.readahead(size)
  end

  env[fn](self.name, hasvalue, size, unpack(self.argv, 1, self.argv.n))
end

function IO:read(fd, data)
  local buf

  if self.size and self.size > 0 then
    buf = fd:read(self.size)
    assert(buf and #buf == self.size, "attempt to read past end of buffer")
  end

  return io(self.name, "unpack", fd, buf, unpack(self.argv, 1, self.argv.n))
end

function IO:readbits(bits, data)
  return io(self.name, "unpackbits", bits, unpack(self.argv, 1, self.argv.n))
end

return IO
