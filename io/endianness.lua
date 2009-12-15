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
-- this is kind of hackish
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
