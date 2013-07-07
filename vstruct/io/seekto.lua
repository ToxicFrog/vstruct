-- @ seek to a constant offset

local seek = {}

function seek.hasvalue()
  return false
end

function seek.width(w)
  assert(tonumber(w), "format requires a size")
  return nil
end

function seek.unpack(fd, _, offset)
  assert(fd:seek("set", offset))
end
seek.pack = seek.unpack

return seek
