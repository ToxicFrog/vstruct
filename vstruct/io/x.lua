-- skip/pad
-- unlike the seek controls @+- or the alignment control a, x will never call
-- seek, and instead uses write '\0' or read-and-ignore - this means it is
-- safe to use on streams.

local io = require "vstruct.io"
local x = {}

function x.hasvalue()
  return false
end

function x.unpack(fd, buf, width)
  io("s", "unpack", fd, buf, width)
  return nil
end

function x.unpackbits(bit, width)
  for i=1,width do
    bit()
  end
end

function x.packbits(bit, _, width, val)
  val = val or 0
  assert(val == 0 or val == 1, "invalid value to `x` format in bitpack: 0 or 1 required, got "..val)
  for i=1,width do
    bit(val or 0)
  end
end

function x.pack(fd, data, width, val)
  return string.rep(string.char(val or 0), width)
end

return x
