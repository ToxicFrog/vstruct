local List = require "vstruct.ast.List"

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
  
  return Bitpack
end
