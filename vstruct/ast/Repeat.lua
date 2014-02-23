return function(count, value)
  local Repeat = {
    tag = "repeat";
    width = (value.width and count * value.width) or nil;
    count = count;
    value = value;
  }
  
  function Repeat:execute(env)
    if count > 0 then
      for i=1,count do
        value:execute(env)
      end
    end
  end

  function Repeat:read(fd, data)
    if count > 0 then
      for i=1,count do
        value:read(fd, data)
      end
    end
  end

  function Repeat:readbits(bits, data)
    if count > 0 then
      for i=1,count do
        value:readbits(bits, data)
      end
    end
  end

  return Repeat
end
