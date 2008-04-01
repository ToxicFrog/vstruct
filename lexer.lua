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

function FIXME_Read_Container(fd)
	local R = {}
	for _,instruction in ipairs(instructions) do
		instruction(fd, R)
	end
	return R
end

function FIXME_Read_IO(fd, R)
	table.insert(R, <<read curry>>(fd))
end

function FIXME_Read_Named_IO(fd, R)
	R[name] = <<read curry>>(fd)
end

function FIXME_Write_Container(fd, W)
	for _,instruction in ipairs(instructions) do
		instruction(fd, W) -- should be W[1] perhaps?
	end
end

function FIXME_Write_IO(fd, W)
	local d = W[1]
	if not <<write curry>>(fd, d) then
		table.remove(W, 1)
	end
end
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
local resolver = { unpack = unpack }
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
		return (translate[type] or type)..' ("'..(width or "")..'"); '
	end

	-- first, we make sure all punctuation is surrounded with whitspace
	-- surround {}()<>= with spaces
	fmt = fmt:gsub('([{}%(%)<>=])', ' %1 ')
	-- turn ' nfw' into ' n* fw'
	-- FIXME we actually strip this since it isn't supported yet
		:gsub('%s+(%d+)%*', ' ')
	-- turn 'fw*n' into 'fw *n'
	-- FIXME we actually strip this since it isn't supported yet
		:gsub('%*(%d+)%s+', ' ')
	-- turn fw into f("w"),
	-- use "w" instead of w so that fixed point works as expected
		:gsub('([<>=])', tr)
		:gsub('([-@+abfimpsuxz])(%d+%.?%d*)', tr)
	-- turn 'foo:fw' into ' foo = fw'
		:gsub('(%a%w*)%:', ' %1 = ')

	local f = loadstring("return unpack { "..fmt.." }")
	return f
end

local translate_r = {
	["<"] = "littleendian";
	[">"] = "bigendian";
	["="] = "hostendian";
	["+"] = "seekforward";
	["-"] = "seekback";
	["@"] = "seekto";
}

function lexer.write(fmt)
	local function tr(type, width)
		return (translate[type] or type)..' ("'..(width or "")..'"), '
	end

	-- first, we make sure all punctuation is surrounded with whitspace
	-- surround {}()<>= with spaces
	fmt = fmt:gsub('([{}%(%)<>=])', ' %1 ')
	-- turn ' nfw' into ' n* fw'
	-- FIXME we actually strip this since it isn't supported yet
		:gsub('%s+(%d+)%*', ' ')
	-- turn 'fw*n' into 'fw *n'
	-- FIXME we actually strip this since it isn't supported yet
		:gsub('%*(%d+)%s+', ' ')
	-- turn fw into f("w"),
	-- use "w" instead of w so that fixed point works as expected
		:gsub('([<>=])', tr)
		:gsub('([-@+abfimpsuxz])(%d+%.?%d*)', tr)
	-- turn 'foo:fw' into ' foo = fw'
		:gsub('(%a%w*)%:', ' %1 = ')
end

return lexer

-- we need to get the fd and, for write mode, the source table
-- write mode is actually going to be Worse Than It Looks, we may
-- need a multi-stage system, or replace { and } in writemode with
-- downshift/upshift

--[[
	a { b c d } e
	a (function(t) b c d end)(???) e

	-- each token should now be one of:
	-- punctuation characters {}()<>=
	-- pre-repetition n*
	-- post-repetition *n
	-- name foo:
	-- format token fn or fn.m
	local cq = {}
	
	while #tokens > 0 do
		local token = table.remove(tokens, 1)
		
		if punctuation[token] then
			table.insert(cq, punctuation[token])
		elseif 
		
	for i,token in ipairs(tokens) do
		-- first check for punctuation
		-- then pre/post repetition
		-- finally, 
			
		
	end
]]

-- cases we need to handle:
-- - next character is one of { } ( )
