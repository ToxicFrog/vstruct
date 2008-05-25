-- write formats
-- return true if they have consumed a value from the input stream
-- return false/nil otherwise (ie, the next value will be preserved
-- for subsequent calls, eg skip/pad)

local name = (...):gsub('%.[^%.]+$', '')
local struct = require (name)
local common = require (name..".common")
local write = setmetatable({}, { __index = common })

--local fp = srequire "struct.fp"

-- boolean
function write.b(fd, d, w)
	return write.u(fd, (d and 1) or 0, w)
end

-- floating point
function write.f(fd, d, w)
	if not fp then
		error("struct.pack: floating point support is not implemented yet")
	elseif not fp.w[w] then
		error("struct.pack: illegal floating point width")
	end
	
	return write.u(fd, fp.w[w](d), w)
end

-- signed int
function write.i(fd, d, w)
	if d < 0 then
		d = d + 2^(w*8)
	end
	return write.u(fd, d, w)
end

-- bitmask
function write.m(fd, d, w)
	return write.u(fd, struct.implode(d), w)
end

-- fixed point bit aligned
function write.P(fd, d, dp, fp)
	assert((dp+fp) % 8 == 0, "total width of fixed point value must be byte multiple")
	return write.u(fd, d * 2^fp, (dp+fp)/8)
end

-- fixed point byte aligned
function write.p(fd, d, dp, fp)
	return write.P(fd, d, dp*8, fp*8)
end

-- fixed length string
-- length 0 is write string as is
-- length >0 is write exactly w bytes, truncating or padding as needed
function write.s(fd, d, w)
	if w == 0 then w = #d end
	if #d < w then
		d = d..string.char(0):rep(w-#d)
	end
	return fd:write(d:sub(1,w))
end

-- unsigned int
function write.u(fd, d, w)
	local s = ""

	for i=1,w do
		if write.is_bigendian then
			s = string.char(d % 2^8) .. s
		else
			s = s .. string.char(d % 2^8)
		end
		d = math.floor(d/2^8)
	end
	
	return write.s(fd, s, w)
end

-- skip/pad
function write.x(fd, d, w)
	write.s(fd, "", w)
	return false
end

-- null terminated string
-- w==0 is write string as is + termination
-- w>0 is write exactly w bytes, truncating/padding and terminating
function write.z(fd, d, w)
	if w == 0 then
		w = #d+1
	elseif #d >= w then
		d = d:sub(1, w-1)
	end
	
	return write.s(fd, d.."\0", w)
end

return write
