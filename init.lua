local struct = {}
struct.cursor = require "struct.cursor"
struct.compile = require "struct.compile"
struct.bigendian = false

-- turn an int into a list of booleans
-- the length of the list will be the smallest number of bits needed to
-- represent the int
function struct.explode(int)
	local mask = {}
	while int ~= 0 do
		table.insert(mask, int % 2 ~= 0)
		int = math.floor(int/2)
	end
	return mask
end

-- turn a list of booleans into an int
-- the converse of explode
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
	-- wrap it in a cursor so we can treat it like a file
	if type(source) == 'string' then
		source = struct.cursor(source)
	end

	assert(source, "invalid first argument to struct.unpack")

	-- the lexer will take our format string and generate code from it
	-- it returns a function that when called with our source, will
	-- unpack the data according to the format string and return all
	-- values from said unpacking
	return struct.compile.read(fmt)(source)
end

-- given a format string and a list of data, pack them
-- if 'fd' is omitted, pack them into and return a string
-- otherwise, write them directly to the given file
function struct.pack(fd, fmt, ...)
	local data,str_fd
	if type(fd) == 'string' then
		data = { fmt, ... }
		fmt = fd
		fd = struct.cursor("")
		str_fd = true
	else
		data = { ... }
	end
	
	struct.compile.write(fmt)(fd, data)
	return (str_fd and fd.str) or fd
end

return struct
