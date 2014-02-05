local unpackenv = require "vstruct.unpack"
local packenv = require "vstruct.pack"
local cursor  = require "vstruct.cursor"

local lua52 = tonumber(_VERSION:match"%d+%.%d+") >= 5.2
local loadstring = lua52 and load or loadstring
local _unpack = table.unpack or unpack

local api = {}

local function checkmethod(obj, name)
  local function check()
    return obj[name]
  end
  local r,e = pcall(check)
  return (r and e)
end

function api.unpack(ast, fd, data)
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
  
  if data == true then
    return _unpack(ast:execute(fd, {}, unpackenv({})))
  else
    return ast:execute(fd, data or {}, unpackenv({}))
  end
end
    
function api.pack(ast, fd, data)
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
  
  local result = ast:execute(realfd, data, packenv({}))
  if realfd == fd then
    return result
  else
    return result.str
  end
end

return api
