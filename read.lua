-- read formats
-- return a value if applicable, which will be packed
-- otherwise return nil

-- load operations common to both read and write, and set __index so that
-- requests for, say, read.seekto will succeed
local name = (...):gsub('%.[^%.]+$', '')
local struct = require (name)
local common = require (name..".common")
local read = setmetatable({}, { __index = common })

-- load the floating point module if available
--local fp = srequire "struct.fp"

-- boolean
-- true if any bit is 1, false otherwise
function read.b(fd, w)
	return read.u(fd, w) ~= 0
end

-- float
-- this is callout to the floating-point read/write module, if installed
function read.f(fd, w)
	if not fp then
		error("struct.unpack: floating point support is not implemented yet")
	elseif not fp.r[w] then
		error("struct.unpack: illegal floating point width")
	end
	
	return fp.r[w](read.u(fd,w))
end

-- signed int of w bytes
function read.i(fd, w)
	local i = read.u(fd, w)
	if i >= 2^(w*8 - 1) then
		return i - 2^(w*8)
	end
	return i
end

-- bitmask of w bytes
function read.m(fd, w)
	return struct.explode(read.u(fd, w))
end

-- fixed point bit aligned
-- w is in the form d.f, where d is the number of bits in the integer part
-- and f the number of bits in the fractional part
function read.P(fd, dp, fp)
	if (dp+fp) % 8 ~= 0 then
		error "total width of fixed point value must be byte multiple"
	end
	return read.u(fd, (dp+fp)/8)/(2^fp)
end

-- fixed point byte aligned
function read.p(fd, dp, fp)
	return read.P(fd, dp*8, fp*8)
end

-- string
-- reads exactly w bytes of data and returns them verbatim
function read.s(fd, w)
	return fd:read(tonumber(w))
end

-- unsigned int
function read.u(fd, w)
	local u = 0
	local s = read.s(fd, w)
	
	-- the "is_bigendian" setting is provided by struct.common
	local sof = (read.is_bigendian and 1 or w)
	local eof = (read.is_bigendian and w or 1)
	local dir = (read.is_bigendian and 1 or -1)
	
	for i=sof,eof,dir do
		u = u * 2^8 + s:sub(i,i):byte()
	end
	
	return u
end

-- skip/pad
-- reads w bytes and discards them
function read.x(fd, w)
	fd:read(w)
	return nil
end

-- null-terminated string
-- if w is 0, reads up to and including the first nul, and returns everything
-- except that nul
-- otherwise, reads exactly w bytes and returns everything up to the first nul
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
