local function store(data, key, val)
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

  function Name:read(fd, data)
    return store(data, key, value:read(fd, data))
  end

  function Name:readbits(bits, data)
    return store(data, key, value:readbits(bits, data))
  end
  
  return Name
end
