return function(key, value)
  local Name = {
    tag = "name";
    width = value.width;
    key = key;
    value = value;
  }
  
  function Name:show()
    io.write("name\t"..key.."\t")
    value:show()
  end
  
  function Name:gen(generator)
    generator:name(key)
    value:gen(generator)
  end

  function Name:execute(env)
    env.name(key)
    value:execute(env)
  end
  
  return Name
end
