-- write formats
-- return true if they have consumed a value from the input stream
-- return false/nil otherwise (ie, the next value will be preserved
-- for subsequent calls, eg skip/pad)

local common = require "struct.common"
local write = setmetatable({}, { __index = common })

local fp = srequire "struct.fp"

-- boolean
function write.b(fd, w, d)
	return write.u(fd, w, (d and 1) or 0)
end

-- floating point
function write.f(fd, w, d)
	if not fp then
		error("struct.pack: floating point support is not loaded")
	elseif not fp.w[w] then
		error("struct.pack: illegal floating point width")
	end
	
	return write.u(fd, fp.w[w](d))
end

-- signed int
function write.i(fd, w, d)
	if d < 0 then
		d = d + 2^(w*8)
	end
	return write.u(fd, w, d)
end

-- bitmask
function write.m(fd, w, d)
	return write.u(fd, w, struct.implode(d))
end

-- fixed point
function write.p(fd, w, d)
	local de,f = string.split(w, '%.')
	if (de+f) % 8 ~= 0 then
		error "total width of fixed point value must be byte multiple"
	end
	return write.u(fd, (de+f)/8, d * 2^f)
end

-- fixed length string
-- length 0 is write string as is
-- length >0 is write exactly w bytes, truncating or padding as needed
function write.s(fd, w, d)
	w = tonumber(w)
	if w == 0 then w = #d end
	if #d < w then
		d = d..string.char(0):rep(w-#d)
	end
	return fd:write(d:sub(1,w))
end

-- unsigned int
function write.u(fd, w, d)
	local s = ""

	for i=1,w do
		if struct.bigendian then
			s = string.char(d % 2^8) .. s
		else
			s = s .. string.char(d % 2^8)
		end
		d = math.floor(d/2^8)
	end
	
	return write.s(fd, w, s)
end

-- skip/pad
function write.x(fd, w, d)
	write.s(fd, w, "")
	return false
end

-- null terminated string
-- w==0 is write string as is + termination
-- w>0 is write exactly w bytes, truncating/padding and terminating
function write.z(fd, w, d)
	if w == 0 then
		w = #d+1
	elseif #d >= w then
		d = d:sub(1, w-1)
	end
	
	return write.s(fd, w, d.."\0")
end

return write
