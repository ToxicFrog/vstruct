local io = require ((...):gsub("%.[^%.]+$", ""))
local z = {}

function z.width(n)
    return tonumber(n)
end

-- null terminated string
-- w==nil is write string as is + termination
-- w>0 is write exactly w bytes, truncating/padding and terminating
function z.pack(_, data, width)
	width = width or #data+1
    
    -- truncate to field width
	if #data >= width then
		data = data:sub(1, width-1)
	end
	
    return io("s", "pack", _, data.."\0", width)
end

-- null-terminated string
-- if w is omitted, reads up to and including the first nul, and returns everything
-- except that nul; WARNING: SLOW
-- otherwise, reads exactly w bytes and returns everything up to the first nul
function z.unpack(fd, buf, width)
    if width then
        return io("s", "unpack", fd, buf, width):match("^%Z*")
    end
    
    local bytes = {}
    local c = fd:read(1)
    while c and c ~= '\0' do
        bytes[#bytes+1] = c
        c = fd:read(1)
    end

    return table.concat(bytes)
end

return z
