-- functions for turning a format string into a callable function
-- two functions are exported, one for read, one for write
-- they work internally by using gsub to translate the format string into
-- executable lua code, then wrapping it in a closure that does scope hacking
-- to make available to it the IO functions.
-- This is a crime against god and man, but it works, and is totally sweet.

require "util"
local read = require "struct.read"
local write = require "struct.write"
local compile = {}


-- we do some trickery here
-- if the user asks for something like @4, the emitted code is "['.'] = a(4)"
-- this way, the returned value (which is nil) doesn't take up a table slot
-- and thus, when unpacked, it doesn't appear in the returned values, and the
-- user doesn't need placeholders
local translate_r = {
	["<"] = "['.'] = littleendian";
	[">"] = "['.'] = bigendian";
	["="] = "['.'] = hostendian";
	["+"] = "['.'] = seekforward";
	["-"] = "['.'] = seekback";
	["@"] = "['.'] = seekto";
	["a"] = "['.'] = a";	-- align
	["x"] = "['.'] = x";	-- skip/pad
}

-- turn a format string into a function that does reads
-- this is done by translating it into lua code which is then compiled using
-- loadstring
-- it returns a function that, when passed a fileoid, does the necessary
-- scope hacking and then executes the function
function compile.read(fmt)
	local function tr(type, width)
		return (translate_r[type] or type)..' ('..(width or ""):gsub('.',',')..'); '
	end

	-- turn ',' and ';', which are permitted but not required, into ' '
	fmt = (" "..fmt.." "):gsub('[,;]', ' ')
	-- make sure all punctuation is surrounded with whitspace
		:gsub('([{}%(%)<>=])', ' %1 ')
		
	-- turn ' n{...}' or ' n*{...}' into repetitions of {...}
		:gsub('%s+(%d+)%*?%s+(%b{})', function(count, action) return (action.."; "):rep(count) end)
	-- turn '{...}n ' or '{...}*n' into repetitions of {...}
		:gsub('(%b{})%s+%*(%d+)%s+', function(action, count) return (action.."; "):rep(count) end)

	-- turn ' n(...)' or ' n*(...)' into repetitions of ...
		:gsub('%s+(%d+)%*%s+(%b())', function(count, action) return action:sub(2,-2):rep(count) end)
	-- turn '(...)n ' or '(...)*n' into repetitions of ...
		:gsub('(%b())%s+%*?(%d+)%s+', function(action, count) return action:sub(2,-2):rep(count) end)

	-- turn fw into f(w),
	-- turn fw.x into f(w,x),
		:gsub('([<>=])', tr)
		:gsub('([-@+abfimpsuxz])(%d+%.?%d*)', tr)

	-- turn 'foo:fw' into ' foo = fw'
		:gsub('(%a%w*)%:', ' %1 = ')

	-- append ; to {} expressions so the lua parser doesn't freak out
		:gsub('}%s', '}; ')

	local f = assert(loadstring("return unpack { "..fmt.." }"))

	return function(source)
		local env = { unpack = unpack }
		function env:__index(key)
			return function(...)
				return read[key](source, ...)
			end
		end
		setmetatable(env, env)
		return setfenv(f, env)()
	end
end

-- unlike translate_r we don't need to worry about discarding return values when
-- writing, so this is just a mapping from format symbols that aren't valid lua
-- identifiers to strings that are
local translate_w = {
	["<"] = "littleendian";
	[">"] = "bigendian";
	["="] = "hostendian";
	["+"] = "seekforward";
	["-"] = "seekback";
	["@"] = "seekto";
}

-- similar to compile.read, but generates code for writing to a fileoid
-- 
function compile.write(fmt)
	local function tr(type, width)
		return (translate_w[type] or type)..' ("'..(width or ""):gsub('.',',')..'") '
	end

	-- turn ',' and ';', which are permitted but not required, into ' '
	fmt = (" "..fmt.." "):gsub('[,;]', ' ')
	-- make sure all punctuation is surrounded with whitspace
		:gsub('([{}%(%)<>=])', ' %1 ')
		
	-- turn ' n{...}' or ' n*{...}' into repetitions of {...}
		:gsub('%s+(%d+)%*?%s+(%b{})', function(count, action) return (action.."; "):rep(count) end)
	-- turn '{...}n ' or '{...}*n' into repetitions of {...}
		:gsub('(%b{})%s+%*(%d+)%s+', function(action, count) return (action.."; "):rep(count) end)

	-- turn ' n(...)' or ' n*(...)' into repetitions of ...
		:gsub('%s+(%d+)%*%s+(%b())', function(count, action) return action:sub(2,-2):rep(count) end)
	-- turn '(...)n ' or '(...)*n' into repetitions of ...
		:gsub('(%b())%s+%*?(%d+)%s+', function(action, count) return action:sub(2,-2):rep(count) end)

	-- { is turned into "make the table which is the next argument be our argument list"
		:gsub('{', 'push_data()')
	
	-- } is turned into "return to the previous argument list and discard the current one"
		:gsub('}', 'pop_data()')

	-- turn fw into f(w)
	-- turn fw.x into f(w,x)
		:gsub('([<>=])', tr)
		:gsub('([-@+abfimpsuxz])(%d+%.?%d*)', tr)

	-- 'foo:fw' is 'the data for this format is taken from args.foo instead of args[1]'
		:gsub('(%a%w*)%:', ' push_var("%1") ')

	local f = assert(loadstring(fmt))
	
	-- this one is somewhat more complicated than the read version, since we need
	-- to supply functions for manipulating the data stack
	return function(source, data)
		local env = {}
		local stack = { data }
		
		function env.push_data()
			table.insert(stack, table.remove(stack[#stack], 1))
		end

		function env.pop_data()
			table.remove(stack)
		end

		function env.push_var(name)
			table.insert(stack[#stack], 1, stack[#stack][name])
		end

		function env:__index(key)
			return function(...)
				local r = write[key](fd, stack[#stack][1], ...)
				if r then table.remove(stack[#stack], 1) end
				return r
			end
		end
		setmetatable(env, env)
		return setfenv(f, env)()
	end
end

return compile
