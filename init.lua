-- vstruct, the versatile struct library
-- Copyright � 2008 Ben "ToxicFrog" Kelly; see COPYING

local table,math,type,require,assert,_unpack = table,math,type,require,assert,unpack
local debug = debug
local print = print

module((...))

cursor = require (_NAME..".cursor")
ast = require (_NAME..".ast")


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
    assert(int, "vstruct.explode: missing argument")
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

function unpack(fmt, src, dst)
    assert(type(fmt) == "string", "invalid first argument to vstruct.unpack")
    assert(src, "missing second argument to vstruct.unpack")
    
    if type(src) == "string" then
        src = cursor(src)
    end
    
    local t = ast.parse(fmt)
    if dst == true then
        return _unpack(t.unpack(src, {}))
    else
        return t.unpack(src, dst or {})
    end
end

function pack(fmt, dst, data)
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

return struct
