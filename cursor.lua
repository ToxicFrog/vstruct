local cursor = {}

function cursor:seek(whence, offset)
	whence = whence or "cur"
	offset = offset or 0
	
	if whence == "set" then
		self.pos = offset
	elseif whence == "cur" then
		self.pos = self.pos + offset
	elseif whence == "end" then
		self.pos = #self.str
	end
	
	return self.pos
end

function cursor:read(n)
	local buf = self.str:sub(self.pos + 1, self.pos + n)
	self.pos = math.min(self.pos + n, #self.str)
	return buf
end

function cursor:write(buf)
	self.str = self.str:sub(1, self.pos)
		.. buf
		.. self.str:sub(self.pos + #buf + 1, -1)
	self.pos = self.pos + #buf
end	

local function make_cursor(self, source)
	return setmetatable(
		{ str = source, pos = 0 },
		{ __index = cursor })
end

setmetatable(cursor, { __call = make_cursor })

return cursor
