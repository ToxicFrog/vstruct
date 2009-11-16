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

function e.get()
    return endianness
end

return e
