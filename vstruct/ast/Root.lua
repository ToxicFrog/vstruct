local io = require "vstruct.io"

return function(child)
  local Root = { child=child }
  
  
  
  function Root:execute(fd, data, env)
    env.initialize(fd, data, env)
    child:execute(env)
    return env.finalize()
  end

  function Root:append(...)
    return child:append(...)
  end

  function Root:read(fd, data)
    io("endianness", "host")
    child:read(fd, data)
    return data
  end
  
  return Root
end
