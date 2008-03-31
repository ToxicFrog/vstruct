require "util"
local cursor = require "struct.cursor"
local common = require "struct.common"
local read = require "struct.read"
local write = require "struct.write"

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
		int = int*2 + (mask[i] and 1) or 0
	end
	return val
end

function struct.unpack(fmt, source)
	-- wrap it in a cursor so we can seek on it and all that
	if type(source) == 'string' then
		source = cursor(source)
	end

	local f = parse(fmt, read)
	return unpack(f())
end

-- given a source, which is either a string or a file handle,
-- unpack it into individual data based on the format string
function struct.unpack(fmt, source)
	-- wrap it in a cursor so we can seek on it and all that
	if type(source) == 'string' then
		source = cursor(source)
	end
	
	local R = {}
	
	local toks = { fmt:split('%s+') }
	for _,token in ipairs(toks) do
		local op,width = token:match('(.)([%d.]+)')
		if not op or not width then
			error "struct.unpack: illegal format string"
		end
		
		print(op, width, read[op])
		R[#R+1] = read[op](source, width)
	end
	
	return unpack(R)
end

function struct.unpack(fmt)
	local t = lex(fmt)
	for k,v in ipairs(t) do print(k,v) end
end

-- given a format string and a list of data, pack them
-- if 'fd' is omitted, pack them into and return a string
-- otherwise, write them directly to the given file
function struct.pack(fd, fmt, ...)
	local data
	if type(fd) == 'string' then
		data = { fmt, ... }
		fmt = fd
	else
		data = { ... }
	end
end

--[[
-- data formats

-- write actions

function write.b(fd, w)
	return write.u(fd, w and 1 or 0)
end

write.f
write.i
write.m
write.s
write.u
write.x
write.z
--]]
