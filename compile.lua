-- functions for turning a format string into a callable function
-- they work by calling parse(), passing it the format string and
-- a table of code generators appropriate for whether we are reading
-- or writing.
-- The resulting code is then prefixed with some setup code and postfixed
-- with a return value and loadstring() is called on it to generate a function
-- Copyright © 2008 Ben "ToxicFrog" Kelly; see COPYING

local require,assert,loadstring,setfenv,error,print,xpcall,type,select,unpack,where
	= require,assert,loadstring,setfenv,error,print,xpcall,type,select,unpack,debug.traceback

module((...))

local parse = require(_PACKAGE.."parser")

local function xpcall2(f, err, ...)  
	local args = {n=select('#', ...), ...}  
	return xpcall(function() return f(unpack(args, 1, args.n)) end, err)  
end

local function err_generate(message, format, trace)
	error([[
struct: internal error in code generator
This is an internal error in the struct library
Please report it as a bug and include the following information:
-- error message
]]..message.."\n\n"..[[
-- format string
]]..format.."\n\n"..[[
-- stack trace
]]..trace)
end

local function err_compile(message, format, source)
	error([[
struct: syntax error in emitted lua source
This is an internal error in the struct library
Please report it as a bug and include the following information:
-- loadstring error
]]..message.."\n\n"..[[
-- format string
]]..format.."\n\n"..[[
-- emitted source
]]..source.."\n\n"..[[
-- stack trace
]])
end

local function err_execute(message, format, source, trace)
	error([[
struct: runtime error in generated function
This is at some level an internal error in the struct library
It could be a genuine error in the emitted code (in which case this is a code
generation bug)
Alternately, it could be that you gave it a malformed format string, a bad
file descriptor, or data that does not match the given format (in which case
it is an argument validation bug and you should be getting an error anyways).
Please report this as a bug and include the following information:
-- execution error
]]..message.."\n\n"..[[
-- format string
]]..format.."\n\n"..[[
-- emitted source
]]..source.."\n\n"..[[
-- stack trace
]]..trace)
end

local function compile(format, cache, gen, env)
	if cache[format] then
		return cache[format]
	end
	
	local status,source = xpcall(function()
		return parse(format, gen, true)
	end,
	function(message)
		return { message, where("",2) }
	end)

	if not status then
		if type(source[1]) == "function" then
			error(source[1]())
		end
		err_generate(source[1], format, source[2])
	end
	
	local fn,err = loadstring(source)
	
	if not fn then
		err_compile(err, format, source)
	end
	
	setfenv(fn, env)
	
	local fn = function(...)
		local status,ret = xpcall2(fn, function(message)
			return { message, where("",2) }
		end, ...)
		
		if status then return ret end
		
		err_execute(ret[1], format, source, ret[2])
	end
	
	cache[format] = fn
	return fn
end

local gen_read = require(_PACKAGE.."gen_read")
local io_read = require(_PACKAGE.."read")
local read_cache = {}

function read(format)
	return compile(format, read_cache, gen_read, io_read)
end

local gen_write = require(_PACKAGE.."gen_write")
local io_write = require(_PACKAGE.."write")
local write_cache = {}

function write(format)
	return compile(format, write_cache, gen_write, io_write)
end

return _M
