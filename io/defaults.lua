local defaults = {}

function defaults.width(n)
    assert(n, "format requires a width")
    return tonumber(n)
end

--[[
function defaults.pack()
    error("pack support not present for this data type")
end

function defaults.unpack()
    error("unpack support not present for this data type")
end
]]

function defaults.validate()
    return true
end

function defaults.hasvalue()
    return true
end

return defaults
