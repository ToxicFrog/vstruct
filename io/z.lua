-- null-terminated strings

local io = require "vstruct.io"
local z = {}

function z.width(width, cwidth)
    return width
end

-- null terminated string
-- w==nil is write string as is + termination
-- w>0 is write exactly w bytes, truncating/padding and terminating

function z.pack(_, data, width, cwidth)
    cwidth = cwidth or 1
	width = width or #data+cwidth
	
	assert(width % cwidth == 0, "string length is not a multiple of character size")
    
    -- truncate to field width
	if #data >= width then
		data = data:sub(1, width-cwidth)
	end
	
    return io("s", "pack", _, data..("\0"):rep(cwidth), width)
end

-- null-terminated string
-- if w is omitted, reads up to and including the first nul, and returns everything
-- except that nul; WARNING: SLOW
-- otherwise, reads exactly w bytes and returns everything up to the first nul
function z.unpack(fd, buf, width, cwidth)
    cwidth = cwidth or 1
    nul = ("\0"):rep(cwidth)
    
    -- read exactly that many characters, then strip the null termination
    if width then
        local buf = io("s", "unpack", fd, buf, width)
        local len = 0
        
        -- search the string for the null terminator. If charwidth > 1, just
        -- finding nul isn't good enough - it needs to be aligned on a character
        -- boundary.
        repeat
            len = buf:find(nul, len+1, true)
        until len == nil or (len-1) % cwidth == 0
        
        return buf:sub(1,(len or 0)-1)
    end
    
    -- this is where it gets ugly: the width wasn't specified, so we need to
    -- read (cwidth) bytes at a time looking for the null terminator
    local chars = {}
    local c = fd:read(cwidth)
    while c and c ~= nul do
        chars[#chars+1] = c
        c = fd:read(cwidth)
    end

    return table.concat(chars)
end

return z
