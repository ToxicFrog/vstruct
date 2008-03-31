--[[
		Control Characters
	@ - seek to offset
	+ - seek forward
	- - seek backward
	a - align to width
	> - big-endian
	< - little-endian
	! - native endianness
		
		Data Characters	
	b - a boolean, 0 is false, nonzero is true
d - an IEEE double precision float, length is not permitted
f - an IEEE floating point number, length is not permitted
	i - a signed integer
m - a bitmask, length is # of bytes, returns as list of booleans
	s - a string, length is mandatory
	u - an unsigned integer
	x - skip length bytes
	z - a null-terminated string, length is max length to read
]]

local function are_we_bigendian()
	return string.byte(string.dump(function() end) == string.char(0x00)
end

local cs = {}
local ds = {}

local code = {}
local data = {}

local function cpush(queue)
	table.insert(cs, queue)
	code = queue
end

local function dpush(queue)
	table.insert(ds, queue)
	data = queue
end

local lexer = {}

-- '('
-- begin grouped code block
function lexer.oparen()
	cpush( {} )
end

-- ')'
-- end grouped code block
function lexer.cparen()
	
end

-- /%*(%d+)/
-- repeat last operation count times
function lexer.dup(count)
	local tail = table.remove(code)
	for i=1,count do
		table.insert(code, tail)
	end
end

-- '{'
-- begin output table
function lexer.obrace()
	cappend(function()
		dpush( {} )
	end)
end

-- '}'
-- end output table
function lexer.cbrace()
	
end

function lexer.endianness(endian)
	local bigendian
	if endian == ">" then
		bigendian = true
	elseif endian == "<" then
		bigendian = false
	else
		bigendian = FIXME_are_we_bigendian;
	end
	
	cappend(function()
		FIXME_set_endian_direction(bigendian)
	end)
end

-- set endianness
tokenacts["[<>=]"] = function(token)
end

-- push code table
tokenacts["("] = function()
	if type(cs:peek()) == 'table' then
		cs:push(#cs:peek() +1)
	end
	cs:push( Queue() )
end

-- pop code table
tokenacts[")"] = function()
	cs:set()
end

-- duplicate code table
tokenacts["%*(%d+)"] = function(count)
	cs:peek():dup(tonumber(count))
end

-- push data table
tokenacts["{"] = function()
	cs:peek():push(function()
		ds:push( Queue() )
	end)
end

-- pop data table
tokenacts["}"] = function()
	cs:peek:push(function()
		ds:set()
	end)
end

-- push name
tokenacts["(%w+):"] = function(name)
	cs:peek:push(function()
		ds:push(name)
	end)
end

-- read
tokenacts["([-+@abcdfimsuxz<>=])(%d*)"] = function(type, width)
end

local function lex(str)
	local tokens = { str:gsub('([(){}<>=])', ' %1 '):gsub(':', ': '):gsub('%*', ' *'):split('[;,%s]%s*') }
	
	for i,token in ipairs(tokens) do
		-- match token
		-- take action
	end
end

module("struct", package.seeall)

local function fields(fmt)
	local function iter()
		print("ITER",fmt)
		if type(fmt) == 'table' then
			for k,v in pairs(fmt) do
				print("",k,v)
			end
		end
		for count,type,width in fmt:gmatch "(%d*)([%@%+%-abcdfimsuxz])(%d*)" do
			count = tonumber(count) or 1
			width = tonumber(width) or 1
			for i=1,count do
				coroutine.yield(type, width)
			end
		end
	end
	return coroutine.wrap(iter)
end

-- read some data from an input descriptor
local function read_bytes(fin, width)
	local buf
	if fin.file then
		buf = fin.fd:read(width)
	else
		buf = fin.fd:sub(fin.offset+1, fin.offset + width)
	end
	fin.offset = fin.offset +width
	return buf
end

local unpack_ops = {}

unpack_ops['@'] = function(fin, width)
	if fin.file then
		fin.fd:seek("set", width)
	end
	fin.offset = width
end

unpack_ops['+'] = function(fin, width)
	if fin.file then
		fin.fd:seek("cur", width)
	end
	fin.offset = fin.offset +width
end

unpack_ops['-'] = function(fin, width)
	if fin.file then
		fin.fd:seek("cur", -width)
	end
	fin.offset = fin.offset -width
end

unpack_ops['a'] = function(fin, width)
	local amount = (width - (fin.offset % width)) % width
	read_bytes(fin, amount)
end

unpack_ops['b'] = function(fin, width)
	local val = unpack_ops.u(fin, width)
	if val == 0 then
		return false
	end
	return true
end

unpack_ops['i'] = function(fin, width)
	local val = unpack_ops.u(fin, width)
	if val < 2^(width*8 - 1) then
		return val
	end
	return val - 2^(width*8)
end

unpack_ops['m'] = function(fin, width)
end

unpack_ops['s'] = function(fin, width)
	return read_bytes(fin, width)
end

unpack_ops['u'] = function(fin, width)
	local buf = 0
	for i=0,width-1 do
		buf = buf + string.byte(read_bytes(fin, 1)) * 2^(i*8)
	end
	return buf
end

unpack_ops['x'] = function(fin, width)
	read_bytes(fin, width)
end

unpack_ops['z'] = function(fin, width)
	local buf = ""
	local char = read_bytes(fin, 1)
	while char ~= "\0" do
		buf = buf..char
		char = read_bytes(fin, 1)
	end
	return buf
end

function unpack(fmt, fin)
	local R = {}
	local fin = { fd = fin; file = (type(fin) ~= "string"); offset = 0; le = true; }
	
	-- first character of < or > forces endianness
	if fmt:sub(1,1) == '>' then
		fin.le = false
		fmt = fmt:sub(2,-1)
	elseif fmt:sub(1,1) == '<' then
		fin.le = true
		fmt = fmt:sub(2,-1)
	end
	
	if fin.file then
		fin.offset = fin:tell()
	end
	
	for type,width in fields(fmt) do
		print("Unpack:", type, width)
		local ret = unpack_ops[type](fin, width)
		table.insert(R, ret)
	end
	return _G.unpack(R)
end

function explode(int, width)
	local mask = {}
	for i=0,width*8-1 do
		if int % 2 == 0 then
			table.insert(mask, false)
		else
			table.insert(mask, true)
		end
		int = math.floor(int/2)
	end
	return mask
end

function implode(mask)
	local val = 0
	for bit,value in ipairs(mask) do
		val = val*2
		val = val + (value and 1) or 0
	end
	return val
end

print("TEST",struct.unpack("s4 s4 @0 s2 @3 s2 @0 u1 @0 u2 @0 u3","11112222"))
print(struct.explode(0x0D, 1))
print(struct.implode({ true, false, true, true }))

