local unpackenv = require "vstruct.unpack"
local packenv = require "vstruct.pack"
local cursor  = require "vstruct.cursor"

local lua52 = tonumber(_VERSION:match"%d+%.%d+") >= 5.2
local loadstring = lua52 and load or loadstring

local function checkmethod(obj, name)
  local function check()
    return obj[name]
  end
  local r,e = pcall(check)
  return (r and e)
end

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
    if lua52 then
      append('local _,_,_ENV = ...')
    end
    append('initialize(...)')
    append('')
  end
  
  function Generator:finalize()
    append('')
    append('return finalize()')
    
    local s = table.concat(source, "\n")
    local f,err = loadstring(s)
    
    if not f then
      error(err.."\n--- internal error in code generator ---\n--- report this as a bug in vstruct ---\n"..s.."\n--- internal error in code generator ---\n")
    end
    
    local u_env = unpackenv(data)
    local p_env = packenv(data)
    
    local _unpack = table.unpack or unpack
    
    local function unpack(fd, data)
      -- autobox strings
      if type(fd) == "string" then
        fd = cursor(fd)
      end
      
      -- fd must have file duck type
      assert(checkmethod(fd, "read"), "invalid fd argument to vstruct.unpack: must be a string or file-like object")
      
      -- data must be true ('return unpacked results')
      -- or false/absent ('create new table')
      -- or a table to fill in
      assert(data == nil or type(data) == "boolean" or type(data) == "table"
        , "invalid data argument to vstruct.unpack: if present, must be table or boolean") 
      
      if not lua52 then
        setfenv(f, u_env)
      end
      
      if data == true then
        return _unpack(f(fd, {}, u_env))
      else
        return f(fd, data or {}, u_env)
      end
    end
    
    local function pack(fd, data)
      if fd and not data then
        data,fd = fd,nil
      end
      
      assert(type(data) == "table", "invalid data argument to vstruct.pack: must be a table")
      
      local realfd
      
      if not fd or type(fd) == "string" then
        realfd = cursor(fd or "")
      else
        realfd = fd
      end
      
      -- fd must have file duck type
      assert(checkmethod(realfd, "write"), "invalid fd argument to vstruct.pack: must be a string or file-like object")
      
      if not lua52 then
        setfenv(f, p_env)
      end
      local result = f(realfd, data, p_env)
      if realfd == fd then
        return result
      else
        return result.str
      end
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
