-- shared formats - seeking, endianness
-- these should all return nil so that they do not mutate the data list

local common = {}

-- determine if the host system is big-endian or not, by dumping an empty
-- function and looking at the endianness flag
local function bigendian()
	return string.byte(string.dump(function() end)) == string.char(0x00)
end

-- seek controls
function common.seekto(fd, w)
	fd:seek("set", w)
end

function common.seekforward(fd, w)
	fd:seek("cur", w)
end

function common.seekback(fd, w)
	fd:seek("cur", -w)
end

function common.a(fd,w)
	local a = fd:seek()
	if a % w ~= 0 then
		fd:seek("cur", w - (a % w))
	end
end

-- endianness controls
function common.littleendian(fd, w)
	struct.bigendian = false
end

function common.bigendian(fd, w)
	struct.bigendian = true
end

function common.hostendian(fd, w)
	struct.bigendian = bigendian()
end

return common
