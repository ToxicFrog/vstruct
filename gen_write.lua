local require,table
	= require,table

module((...))
local parse = require(_PACKAGE.."parser")

local gen = {}

gen.preamble = [[
local fd,data = ...
local stack = {}
local index = 1

local function push(key)
	if not key then
		key = index
		index = index + 1
	end
	
	stack[#stack+1] = { index, data }
	data = data[key]
	index = 1
end

local function pop(key)
	local saved = stack[#stack]
	stack[#stack] = nil
	
	index = saved[1]
	data = saved[2]
end

hostendian()
]]		

gen.postamble = [[

return fd
]]

--	control:
--		<<type>>(fd, <<args>>)
function gen.control(token)
	local tr = {
		["<"] = "littleendian";
		[">"] = "bigendian";
		["="] = "hostendian";
		["+"] = "seekforward";
		["-"] = "seekback";
		["@"] = "seekto";
	}
	local fn = tr[token[1]] or token[1]

	local args = token[2]:gsub('%.', ', ')
	if #args == 0 then args = "nil" end

	return fn.."(fd, "..args..")"
end

--	atom:
--		<<type>>(fd, data[index], <<args>>)
--		++index
function gen.atom(token)
	local fn = token[1]
	local args = token[2]:gsub('%.', ', ')
	if #args == 0 then args = "nil" end

	return fn.."(fd, data[index], "..args..")\nindex = index+1"
end

--	table:
--		push()
--		<<table contents>>
--		pop()
function gen.table(token)
	return "push()\n"
	..parse(token[1]:sub(2,-2), gen)
	.."\npop()"
end

--	group:
--		<<group contents>>
function gen.group(token)
	return parse(token[1]:sub(2,-2), gen)
end

-- named atom:
--		<<type>>(fd, data.<<name>>, <<args>>)
function gen.name_atom(token)
	local fn = token[2]
	local args = token[3]:gsub('%.', ', ')
	if #args == 0 then args = "nil" end

	return fn.."(fd, data."..token[1]..", "..args..")"	
end

-- named table:
--		push(<<name>>)
--		<<table contents>>
--		pop()
function gen.name_table(token)
	return "push('"..token[1].."')\n"
	..parse(token[2]:sub(2,-2), gen)
	.."\npop()"
end

function gen.prerepeat(token, get)
	local next = get()
	local src = gen[next.type](next, get)
	
	return "for _idx=1,"..token[1].." do\n\n"..src.."\nend"
end

function gen.postrepeat(token, get, asl)
	local src = table.remove(asl)
	
	return "for _idx=1,"..token[1].." do\n\n"..src.."\nend"
end

return gen

