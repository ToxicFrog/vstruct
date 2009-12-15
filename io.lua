local _M = (...)

local defaults = require (_M..".defaults");


local formats = {}

local function iorequire(format)
    local r,v = pcall(require, _M.."."..format)

    if not r then
        error("struct: no support for format '"..format.."':\n"..tostring(v))
    end
    
    return v                   
end

local controlnames = {
    seekf   = "+";
    seekb   = "-";
    seekto  = "@";
    bigendian   = ">";
    littleendian= "<";
    hostendian  = "=";
}

for name,symbol in pairs(controlnames) do
    package.preload[_M.."."..symbol] = function() return iorequire(name) end
end

return function(format, method, ...)
    local fmt = formats[format]
        or setmetatable(iorequire(format), { __index = defaults })
    
    assert(fmt[method], "No support for method '"..tostring(method).."' in IO module '"..format.."'")
    
    return fmt[method](...)
end
