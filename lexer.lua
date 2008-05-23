-- lexer module for struct
-- turn a format string into a sequence of calls

-- the contract of the read parser is that it will turn a token stream into
-- a function which, when called with an fd and with a container table, packs
-- the results of the reads into the container and returns it.


-- the contract of the write parser is that it will turn a token stream into
-- a function which, when called with an fd and a list of input data, will
-- perform the corresponding writes on the fd

--[[
I have a horrible awesome idea
Use regex abuse to transform the input string into valid ordered lua code, and compile it
something like:

%w%d -> %1(fd, %2);
name:... -> name = ...
{ ... } -> { ... };
*n -> ???
( ... ) -> ???

--]]

-- for reading - we get a table; we call each reader in turn; we pack the
-- value it returns into the table
-- for subtables, we get another table and pack into that - do this with
-- recursion?

-- {} needs to be surrounded with an implicit (), so that stuff
-- like n*{...} and {...}*n will work
-- this doesn't solve foo:{...}, though
-- of course! {...} turns into a single function that processes the table
-- constructor and returns the resulting table
-- foo: bar composes into a single function (set foo (bar))
-- <>= set endianness
-- n* multiply next entry on execution stack
-- *n multiply last entry on execution stack
-- foo: wrap next entry on execution stack in name assignment

-- *n we need to process at lex time
-- n* we need to process at execute time? or use get_next_operation?

-- parse - process the token stream until EOF or until the table pops
-- then pack everything it got into a function and return it
-- this allows us to process n* and foo:!

--[[
	so the top level looks something like
	local R = parse(token_stream)()
	return unpack(R)
]]

require "util"
local read = require "struct.read"
local write = require "struct.write"
local lexer = {}


-- table of translations for weird symbols that aren't valid Names
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
		return (translate_r[type] or type)..' ("'..(width or "")..'"); '
	end

	-- turn ',' and ';', which are permitted but not required, into ' '
	fmt = (" "..fmt.." "):gsub('[,;]', ' ')
	-- make sure all punctuation is surrounded with whitspace
	-- surround {}()<>= with spaces
		:gsub('([{}%(%)<>=])', ' %1 ')
	-- turn ' n{...}' or ' n*{...}' into repetitions of {...}
		:gsub('%s+(%d+)%*?%s+(%b{})', function(count, action) return (action.."; "):rep(count) end)
	-- turn '{...}n ' or '{...}*n' into repetitions of {...}
		:gsub('(%b{})%s+%*(%d+)%s+', function(action, count) return (action.."; "):rep(count) end)

	-- turn ' n(...)' or ' n*(...)' into repetitions of ...
		:gsub('%s+(%d+)%*%s+(%b())', function(count, action) return action:sub(2,-2):rep(count) end)
	-- turn '(...)n ' or '(...)*n' into repetitions of ...
		:gsub('(%b())%s+%*?(%d+)%s+', function(action, count) return action:sub(2,-2):rep(count) end)

	-- turn fw into f("w"),
	-- use "w" instead of w so that fixed point works as expected
		:gsub('([<>=])', tr)
		:gsub('([-@+abfimpsuxz])(%d+%.?%d*)', tr)

	-- turn 'foo:fw' into ' foo = fw'
		:gsub('(%a%w*)%:', ' %1 = ')

	-- append ; to {} expressions so the lua parser doesn't freak out
		:gsub('}%s', '}; ')

	local f = assert(loadstring("return unpack { "..fmt.." }"))
	return f
end

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
		return (translate_w[type] or type)..' ("'..(width or "")..'") '
	end

	-- turn ',' and ';', which are permitted but not required, into ' '
	fmt = (" "..fmt.." "):gsub('[,;]', ' ')
	-- make sure all punctuation is surrounded with whitspace
	-- surround {}()<>= with spaces
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

	-- turn fw into f("w"),
	-- use "w" instead of w so that fixed point works as expected
		:gsub('([<>=])', tr)
		:gsub('([-@+abfimpsuxz])(%d+%.?%d*)', tr)

	-- 'foo:fw' is 'the data for this format is taken from args.foo instead of args[1]'
		:gsub('(%a%w*)%:', ' push_var("%1") ')

	return assert(loadstring(fmt))
end

return lexer
