-- lexer module for struct
-- turn a format string into a sequence of calls

-- the contract of the read parser is that it will turn a token stream into
-- a function which, when called with an fd and with a container table, packs
-- the results of the reads into the container and returns it.


-- the contract of the write parser is that it will turn a token stream into
-- a function which, when called with an fd and a list of input data, will
-- perform the corresponding writes on the fd

require "util"
local read = require "struct.read"
local write = require "struct.write"
local lexer = {}


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

function lexer.read(fmt)
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
			return function(w)
				return read[key](source, w)
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

function lexer.write(fmt)
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
			return function(w)
				local r = write[key](fd, w, stack[#stack][1])
				if r then table.remove(stack[#stack], 1) end
				return r
			end
		end
		setmetatable(env, env)
		return setfenv(f, env)()
	end
end

return lexer
