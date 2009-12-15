local defaults = {}

function defaults.width(n)
    assert(tonumber(n), "format requires a width")
    return tonumber(n)
end

function defaults.validate()
    return true
end

function defaults.hasvalue()
    return true
end

return defaults
