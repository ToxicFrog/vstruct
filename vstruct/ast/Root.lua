return function(child)
  local Root = {}
  
  function Root:execute(fd, data, env)
    env.initialize(fd, data, env)
    child:execute(env)
    return env.finalize()
  end

  function Root:append(...)
    return child:append(...)
  end
  
  return Root
end
