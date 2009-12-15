local unpackenv = require ((...):gsub("ast%.Generator$", "unpack"))
local packenv = require ((...):gsub("ast%.Generator$", "pack"))

return function()
    local Generator = {}
    
    local source = {}
    local data = {}
    local readahead = nil
    local ra_left = nil
    local indent = 0
    local bitpack = false
    local loopmul = 1
    
    local function append(...)
        source[#source+1] = string.rep(" ", indent)..string.format(...)
    end
    
    local function ref(v)
        data[#data+1] = v
        return #data
    end
    
    function Generator:init()
        append('initialize(...)')
        append('')
    end
    
    function Generator:finalize()
        append('')
        append('return finalize()')
        
        local s = table.concat(source, "\n")
        local f = assert(loadstring(s))
        local u_env = unpackenv(data)
        local p_env = packenv(data)
        
        local function unpack(fd, data)
            setfenv(f, u_env)
            return f(fd, data)
        end
        
        local function pack(fd, data)
            setfenv(f, p_env)
            return f(fd, data)
        end
        
        return { pack=pack, unpack=unpack, source=s }
    end
    
    function Generator:io(name, hasvalue, width, args)
        append('%sio(%q, %s, %s%s%s)'
            , bitpack and "bp" or ""
            , name
            , tostring(hasvalue)
            , tostring(width)
            , args and ", " or ""
            , args or "")

        if readahead then
            ra_left = ra_left - width * loopmul
            assert(ra_left >= 0
                , string.format("code generation consistency failure: readahead=%d, left=%f"
                    , readahead
                    , ra_left))
            if ra_left == 0 then
                readahead = nil
                ra_left = nil
                append('-- end readahead')
            end
        end
    end
    
    function Generator:readahead(n)
        if n and n > 0 and not readahead then
            readahead = n
            ra_left = n * loopmul
            append('readahead(%d)', n)
        end
    end
    
    function Generator:startloop(n)
        append('for _=1,%d do', n)
        indent = indent + 2
        loopmul = loopmul * n
    end
    
    function Generator:endloop(n)
        loopmul = loopmul / n
        indent = indent - 2
        append('end')
    end
    
    function Generator:starttable()
        append('push()')
        indent = indent + 2
    end
    
    function Generator:endtable()
        indent = indent - 2
        append('pop()')
    end
    
    function Generator:name(name)
        append('name %q', name)
    end
    
    function Generator:bitpack(size)
        if size then
            if bitpack then
                error("nested bitpacks are not permitted")
            end
            append('bitpack(%d)', size)
            bitpack = size
            if readahead then
                ra_left = ra_left * 8
            end
        else
            append('bitpack(nil)')
            bitpack = false
            if readahead then
                ra_left = ra_left / 8
            end
        end
    end
    
    return Generator
end
