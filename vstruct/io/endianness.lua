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

-- determine if the host system is big-endian or not, by dumping an empty
-- function and looking at the endianness flag
-- HACK HACK HACK
function e.host()
    if string.byte(string.dump(function() end)) == 0x00 then
        e.big()
    else
        e.little()
    end
end

function e.get()
    return endianness
end

return e
