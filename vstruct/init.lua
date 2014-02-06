-- vstruct, the versatile struct library

-- Copyright (C) 2011 Ben "ToxicFrog" Kelly; see COPYING

local table,math,type,require,assert,_unpack = table,math,type,require,assert,unpack
local debug = debug
local print = print

local vstruct = {}
package.loaded.vstruct = {}

vstruct._NAME = "vstruct"
vstruct._VERSION = "1.1.4"
vstruct._M = vstruct

vstruct.cursor = require "vstruct.cursor"

local api = require "vstruct.api"

-- cache control for the parser
-- true: cache is read/write (new formats will be cached, old ones retrieved)
-- false: cache is read-only
-- nil: cache is disabled
vstruct.cache = true

-- detect system endianness on startup
require "vstruct.io" ("endianness", "probe")

-- this is needed by some IO formats as well as init itself
-- FIXME: should it perhaps be a vstruct internal function rather than
-- installing it in math?
if not math.trunc then
  function math.trunc(n)
    if n < 0 then
      return math.ceil(n)
    else
      return math.floor(n)
    end
  end
end

-- turn an int into a list of booleans
-- the length of the list will be the smallest number of bits needed to
-- represent the int
function vstruct.explode(int, size)
  size = size or 0
  api.check_arg("explode", 1, int, "number")
  api.check_arg("explode", 2, size, "number")

  local mask = {}
  while int ~= 0 or #mask < size do
    table.insert(mask, int % 2 ~= 0)
    int = math.trunc(int/2)
  end
  return mask
end

-- turn a list of booleans into an int
-- the converse of explode
function vstruct.implode(mask, size)
  api.check_arg("implode", 1, mask, "table")
  size = size or #mask
  api.check_arg("implode", 2, size, "number")
  
  local int = 0
  for i=size,1,-1 do
    int = int*2 + ((mask[i] and 1) or 0)
  end
  return int
end

-- Given a format string, a buffer or file, and an optional third argument,
-- unpack data from the buffer or file according to the format string
function vstruct.unpack(fmt, ...)
  api.check_arg("unpack", 1, fmt, "string")
  local t = api.compile(fmt)
  return t.unpack(...)
end

-- Given a format string, an optional file-like, and a table of data,
-- pack data into the file-like (or create and return a string of packed data)
-- according to the format string
function vstruct.pack(fmt, ...)
  api.check_arg("pack", 1, fmt, "string")
  local t = api.compile(fmt)
  return t.pack(...)
end

-- Given a format string, compile it and return a table containing the original
-- source and the pack/unpack functions derived from it.
function vstruct.compile(fmt)
  api.check_arg("compile", 1, fmt, "string")
  return api.compile(fmt)
end

-- Takes the same arguments as vstruct.unpack()
-- returns an iterator over the input, repeatedly calling unpack until it runs
-- out of data
function vstruct.records(fmt, fd, unpacked)
  local t = api.compile(fmt)
  if type(fd) == "string" then
    fd = vstruct.cursor(fd)
  end
  
  return function()
    if fd:read(0) then
      return t.unpack(fd, unpacked)
    end
  end
end

return vstruct
