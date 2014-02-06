return function(key, value)
  local Name = {
    tag = "name";
    width = value.width;
    key = key;
    value = value;
  }
  
  function Name:execute(env)
    env.name(key)
    value:execute(env)
  end
  
  return Name
end
