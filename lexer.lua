-- lexer module for struct
-- turn a format string into a sequence of calls

-- the contract of the read parser is that it will turn a token stream into
-- a function which, when called with an fd and with a container table, packs
-- the results of the reads into the container and returns it.


-- the contract of the write parser is that it will turn a token stream into
-- a function which, when called with an fd and a list of input data, will
-- perform the corresponding writes on the fd

--[[
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

local function wrap(ops, op, width, d)
	return function(fd)
		return ops[op](fd, width, d)
	end
end
		

function parse(next)
	local cq = {}
	for token in next do
		-- token processing
		-- <>= turn into endianness control functions
		-- @+-a turn into seek functions through wrap
		-- pre-repetition gets the next() token and repeats it
		-- post-repetition pops the previous token and repeats it
		-- name gets the next() token and wraps it in a naming function
		-- everything else turns into an io function
	end
	-- we return a function that when called executes the instruction list
	-- we've created and returns a table containing everything we extracted
	-- from those functions
	-- we need seperate versions of these for read and write
	return function(fd)
		local t = {}
		for _,c in ipairs(cq) do
			c(fd, t)
		end
		return t
	end	
end

-- break a format string down into individual tokens
-- this is mode-agnostic
function lex(fmt)
	-- tokenize
	-- first, we make sure all punctuation is surrounded with whitspace
	fmt = fmt:gsub('([{}%(%)<>=])', ' %1 ')
	-- turn ' nfw' into ' n* fw'
		:gsub('%s+(%d+)', ' %1* ')
	-- turn 'fw*n' into 'fw *n'
		:gsub('%*(%d+) ', ' *%1 ')
	-- turn 'foo:fw' into ' foo: fw'
		:gsub('(%a%w*%:)', ' %1 ')
	
	-- now we can just split
	tokens = { fmt:trim():split('%s+') }
	
	return tokens
end
--[[
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
