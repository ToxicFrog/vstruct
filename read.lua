-- read formats
-- return a value if applicable, which will be packed
-- otherwise return nil

local common = require "struct.common"
local read = setmetatable({}, { __index = common })

local fp = srequire "struct.fp"

-- boolean
function read.b(fd, w)
	return read.u(fd, w) ~= 0
end

-- float
function read.f(fd, w)
	if not fp then
		error("struct.unpack: floating point support is not loaded")
	elseif not fp.r[w] then
		error("struct.unpack: illegal floating point width")
	end
	
	return fp.r[w](read.u(fd,w))
end

-- signed int
function read.i(fd, w)
	local i = read.u(fd, w)
	if i >= 2^(w*8 - 1) then
		return i - 2^(w*8)
	end
	return i
end

-- bitmask
function read.m(fd, w)
	return struct.explode(read.u(fd, w))
end

-- fixed point
function read.p(fd, w)
	local d,f = string.split(w, '%.')
	if (d+f) % 8 ~= 0 then
		error "total width of fixed point value must be byte multiple"
	end
	return read.u(fd, (d+f)/8)/(2^f)
end

-- string
function read.s(fd, w)
	return fd:read(tonumber(w))
end

-- unsigned int
function read.u(fd, w)
	local u = 0
	local s = read.s(fd, w)
	
	local sof = (struct.bigendian and 1 or w)
	local eof = (struct.bigendian and w or 1)
	local dir = (struct.bigendian and 1 or -1)
	
	for i=sof,eof,dir do
		u = u * 2^8 + s:sub(i,i):byte()
	end
	
	return u
end

-- skip/pad
function read.x(fd, w)
	fd:read(w)
	return nil
end

-- null-terminated string
function read.z(fd, w)
	if tonumber(w) ~= 0 then
		return read.s(fd, w):match('^%Z*')
	end
	
	local buf
	local c = read.s(fd, 1)
	while #c > 0 and c ~= string.char(0) do
		buf = buf..c
		c = read.s(fd, 1)
	end
	return buf
end

return read
