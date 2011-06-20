-- the actual endianness controls. These should not be used directly, but
-- are instead invoked by the <=> formats (bigendian, littleendian, and
-- hostendian) to do the actual work.

-- FIXME: endianness flag should be operation-local rather than VM-local; at
-- present packunpack operations are atomic, but if in the future they are
-- not - for example, if an io is implemented that uses coroutines - the current
-- implementation will fuck us right up.

local e = {}

local endianness;

function e.hasvalue()
    return false
end

function e.big()
    endianness = "big"
end

function e.little()
    endianness = "little"
end

-- select whichever endianness the host system uses
local bigendian
function e.host()
    local function aux(be)
        return be and e.big() or e.little()
    end
    

    -- we cache the result in "bigendian_system" to avoid creating an dumping
    -- a function every single time anything happens
    if bigendian ~= nil then
        return aux(bigendian)
    
    -- if we're running in luajit, we can just query the FFI library
    elseif jit then
        bigendian = require("ffi").abi("be")
        
    -- if we're not, we dump an empty function and see if the first byte is nul
    -- or not. HACK HACK HACK - this is unlikely to work in anything but the
    -- reference implementation.
    elseif string.dump then
        bigendian = string.byte(string.dump(function() end)) == 0x00
        
    -- if neither jit nor string.dump is available, we guess wildly that it's
    -- a little-endian system (and emit a warning)
    else
        io.stderr:write("[vstruct] Warning: can't determine endianness of host system, assuming litle-endian")
        bigendian = false
    end
    
    return aux(bigendian)
end

function e.get()
    return endianness
end

return e
