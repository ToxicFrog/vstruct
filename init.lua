require "util"
local cursor = require "struct.cursor"
local common = require "struct.common"
local read = require "struct.read"
local write = require "struct.write"
local lexer = require "struct.lexer"

struct = {}
struct.bigendian = false	-- FIXME

-- turn an int into a list of booleans
function struct.explode(int)
	local mask = {}
	while int ~= 0 do
		table.insert(mask, int % 2 ~= 0)
		int = math.floor(int/2)
	end
	return mask
end

-- turn a list of booleans into an int
function struct.implode(mask)
	local int = 0
	for i=#mask,1,-1 do
		int = int*2 + ((mask[i] and 1) or 0)
	end
	return int
end

-- given a source, which is either a string or a file handle,
-- unpack it into individual data based on the format string
function struct.unpack(source, fmt)
	-- wrap it in a cursor so we can seek on it and all that
	if type(source) == 'string' then
		source = cursor(source)
	end

	local f = lexer.read(fmt)

	-- we provide a custom environment which wraps the reader
	-- functions so that the source is provided to them
	local resolver = { unpack = unpack }
	function resolver:__index(key)
		return function(w)
			return read[key](source, w)
		end
	end
	setmetatable(resolver, resolver)
	
	-- the unpack() is built in, so just tail call
	return setfenv(f, resolver)()
end

-- given a format string and a list of data, pack them
-- if 'fd' is omitted, pack them into and return a string
-- otherwise, write them directly to the given file
function struct.pack(fd, fmt, ...)
	local data
	if type(fd) == 'string' then
		data = { fmt, ... }
		fmt = fd
		fd = cursor("")
	else
		data = { ... }
	end
	
	local f = lexer.write(fmt)
	local resolver = {}
	function resolver:__index(key)
		return function(w)
			local r = write[key](fd, w, data[1])
			if r then table.remove(data, 1) end
			return r
		end
	end
	
	return setfenv(f, resolver)()
end
