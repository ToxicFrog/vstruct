-- vstruct, the versatile struct library

-- Copyright (C) 2011 Ben "ToxicFrog" Kelly; see COPYING

local table,math,type,require,assert,_unpack = table,math,type,require,assert,unpack
local debug = debug
local print = print

module "vstruct"

_VERSION = "1.1"

cursor = require "vstruct.cursor"

local ast = require "vstruct.ast"

-- cache control for the parser
-- true: cache is read/write (new formats will be cached, old ones retrieved)
-- false: cache is read-only
-- nil: cache is disabled
cache = true

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
function explode(int, size)
    assert(int, "vstruct.explode: missing argument")
    size = size or 0
    
    local mask = {}
    while int ~= 0 or #mask < size do
        table.insert(mask, int % 2 ~= 0)
        int = math.trunc(int/2)
    end
    return mask
end

-- turn a list of booleans into an int
-- the converse of explode
function implode(mask, size)
    size = size or #mask
    
    local int = 0
    for i=size,1,-1 do
        int = int*2 + ((mask[i] and 1) or 0)
    end
    return int
end

-- Given a format string, a buffer or file, and an optional third argument,
-- unpack data from the buffer or file according to the format string
function unpack(fmt, ...)
    assert(type(fmt) == "string", "invalid first argument to vstruct.unpack")
    
    local t = ast.parse(fmt)
    return t.unpack(...)
end

-- Given a format string, an optional file-like, and a table of data,
-- pack data into the file-like (or create and return a string of packed data)
-- according to the format string
function pack(fmt, ...)
    local t = ast.parse(fmt)
    return t.pack(...)
end

-- Given a format string, compile it and return a table containing the original
-- source and the pack/unpack functions derived from it.
function compile(fmt)
	return ast.parse(fmt)
end

return _M
