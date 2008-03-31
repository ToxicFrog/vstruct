-- shared formats - seeking, endianness
-- these should all return nil so that they do not mutate the data list

local common = {}

local function bigendian()
	return string.byte(string.dump(function() end)) == string.char(0x00)
end


-- seek controls
common["@"] = function(fd, w)
	fd:seek("set", w)
end

common["+"] = function(fd, w)
	fd:seek("cur", w)
end

common["-"] = function(fd, w)
	fd:seek("cur", -w)
end

common["a"] = function(fd, w)
	local a = fd:seek()
	if a % w ~= 0 then
		fd:seek("cur", w - (a % w))
	end
end

-- endianness controls
common["<"] = function(fd, w)
	struct.bigendian = false
end

common[">"] = function(fd, w)
	struct.bigendian = true
end

common["="] = function(fd, w)
	struct.bigendian = bigendian()
end

return common
