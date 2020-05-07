-- math.frexp() replacement for Lua 5.3 when compiled without LUA_COMPAT_MATHLIB.
-- The C approach is just to type-pun the float, but we can't do that here short
-- of stupid loadstring() tricks, which would be both architecture and version
-- dependent and a maintenance headache at best. So instead we use math.

local abs,floor,log = math.abs,math.floor,math.log
local log2 = log(2)

return function(x)
  if x == 0 then return 0.0,0.0 end
  local e = floor(log(abs(x)) / log2)
  if e > 0 then
    -- Why not x / 2^e? Because for large-but-still-legal values of e this
    -- ends up rounding to inf and the wheels come off.
    x = x * 2^-e
  else
    x = x / 2^e
  end
  -- Normalize to the range [0.5,1)
  if abs(x) >= 1.0 then
    x,e = x/2,e+1
  end
  return x,e
end
