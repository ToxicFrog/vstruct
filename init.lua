-- vstruct, the versatile struct library
-- Copyright � 2008 Ben "ToxicFrog" Kelly; see COPYING

local table,math,type,require,assert,_unpack = table,math,type,require,assert,unpack
local debug = debug
local print = print

module((...))

cursor = require (_NAME..".cursor")
--compile = require (_NAME..".compile")

cache = true

function math.trunc(n)
    if n < 0 then
        return math.ceil(n)
    else
        return math.floor(n)
    end
end

-- turn an int into a list of booleans
-- the length of the list will be the smallest number of bits needed to
-- represent the int
function explode(int, size)
    assert(int, "struct.explode: missing argument")
    size = size or 0
    
    local mask = {}
    while int ~= 0 or #mask < size do
        table.insert(mask, int % 2 ~= 0)
        int = math.trunc(int/2)
    end
    return mask
end

-- turn a list of booleans into an int
-- the converse of explode
function implode(mask, size)
    size = size or #mask
    
    local int = 0
    for i=size,1,-1 do
        int = int*2 + ((mask[i] and 1) or 0)
    end
    return int
end

function parsetest(fmt, data)
    local ast = require(_NAME..".ast")
    --    ast.parse(fmt) --:show()
    local t = ast.parse(fmt):unpack(nil,data)
    print("--")
    table.print(t)
    --    table.print(ast.parse(fmt):unpack(nil, ""))
end

function unpack(fmt, src, dst)
    local ast = require "struct.ast"
    
    assert(type(fmt) == "string", "invalid first argument to vstruct.unpack")
    assert(src, "missing second argument to vstruct.unpack")
    
    if type(src) == "string" then
        src = cursor(src)
    end
    
    local t = ast.parse(fmt)
    return t.unpack(src, dst or {})
end

function pack(fmt, dst, data)
    local ast = require "struct.ast"
    local str
    
    if not data then
        data = dst
        dst = cursor("")
        str = true
    end
    
    local t = ast.parse(fmt)
    local v = t.pack(dst, data)
    if str then
        return v.str
    else
        return v
    end
end

-- given a format string and a list of data, pack them
-- if 'fd' is omitted, pack them into and return a string
-- otherwise, write them directly to the given file
function old_pack(fmt, fd, data)
    local str_fd
    
    if not data then
        data = fd
        fd = ""
    end
    
    if type(fd) == 'string' then
        fd = cursor("")
        str_fd = true
    end
    
    assert(fmt and fd and data and type(fmt) == "string", "struct: invalid arguments to pack")
    
    local fd,len = compile.pack(fmt)(fd, data)
    return (str_fd and fd.str) or fd,len
end

return struct
