local List = require "vstruct.ast.List"
local io = require "vstruct.io"

-- return an iterator over the individual bits in buf
local function biterator(buf)
  local e = io("endianness", "get")
  
  local data = { buf:byte(1,-1) }
  local bit = 7
  local byte = e == "big" and 1 or #data
  local delta = e == "big" and 1 or -1

  return function()    
    local v = math.floor(data[byte]/(2^bit)) % 2
    
    bit = (bit - 1) % 8
    
    if bit == 7 then -- we just wrapped around
      byte = byte + delta
    end

    return v
  end
end

return function(size)
  local Bitpack = {
    tag = "bitpack";
    width = size;
  }
  
  local children = List();
  
  function Bitpack:append(node)
    children:append(node)
    assert(children.width, "bitpacks cannot contain variable-width fields")
    assert(children.width <= size*8, "bitpack contents are larger than containing bitpack")
  end
  
  function Bitpack:finalize()
    assert(children.width == size*8, "bitpack contents are smaller than containing bitpack")
  end
  
  function Bitpack:execute(env)
    env.readahead(size)
    env.bitpack(size)
    children:execute(env)
    env.bitpack()
  end

  function Bitpack:read(fd, data)
    local buf = fd:read(size)
    children:readbits(biterator(buf), data)
  end
  
  return Bitpack
end
