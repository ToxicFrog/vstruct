local io = require ((...):gsub("pack$", "io"))

return function(refs)
    local env = {}
    
    local fd,buffer,bufsize,bufpos,data,stack,key,index,istack
    local bitpack,nextbit
    
    local function get()
        local value
        if not key then
            value = data[index]
            index = index+1
        else
            local data = data
            for name in key:gmatch("([^%.]+)%.") do
                data = assert(data[name], "malformed table passed to pack")
            end
            value = data[key:match("[^%.]+$")]
            key = nil
        end
        return value
    end
    
    local function write(v)
        if not buffer then
            fd:write(v)
        else
            bufpos = bufpos + #v
            buffer[#buffer+1] = v
                
            if bufpos == bufsize then
                fd:write(table.concat(buffer))
                buffer = nil
            end
        end
    end
    
    function env.ref(id)
        return unpack(refs[id])
    end
    
    function env.initialize(_fd, _data)
        fd = _fd
        
        buffer,bufsize,bufpos = nil,0,0
        
        data = _data
        stack = {}
        
        index = 1
        istack = {}
        
        key = nil
    end
    
    function env.readahead(n)
        assert(bufpos == bufsize, "internal consistency failure: overlapping readahead")
        
        buffer = {}
        bufsize = n
        bufpos = 0
    end
    
    function env.name(name)
        key = name
    end
    
    function env.push()
        local t = get()

        stack[#stack+1] = data
        data = t

        istack[#istack+1] = index
        index = 1
    end
    
    function env.pop()
        data = stack[#stack]
        stack[#stack] = nil
        
        index = istack[#istack]
        istack[#istack] = nil
    end
    
    function env.io(name, hasvalue, width, ...)
        local v = io(name, "pack", fd, hasvalue and get() or nil, ...)
        
        if v then
            assert((not width) or #v == width, "pack format '"..name.."' lied about its width!")
            write(v)
        end
    end
    
    function env.bpio(name, hasvalue, width, ...)
        return io(name, "packbits", nextbit, hasvalue and get() or nil, ...)
    end
    
    function env.bitpack(width)
        if width then
            bitpack = {}
            for i=1,width do
                bitpack[i] = 0
            end
        
            local e = io("endianness", "get")
            
            local bbit = 0
            local bbyte = e == "big" and #bitpack or 1
            local bdelta = e == "big" and -1 or 1
            
            function nextbit(b)
                bitpack[bbyte] = bitpack[bbyte] + b * 2^bbit

                if bbit < 7 then
                    bbit = bbit+1
                else
                    bbit = 0
                    bbyte = bbyte+bdelta
                end
            end
        else
            write(string.char(unpack(bitpack)))
            bitpack = nil
        end
    end
    
    function env.finalize()
        assert(#stack == 0, "mismatched push/pop in execution")
        return fd
    end
    
    do return env end
    
    return setmetatable({}, {
        __index = function(_, key)
            return function(...)
                print("pack", key, ...)
                return env[key](...)
            end
        end;
    })
end