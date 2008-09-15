local gen = {}

gen.preamble = [[
local fd = (...)
local stack = {}
local pack = {}

local function push()
	stack[#stack+1],pack = pack,{}
end

local function pop(key)
	local target = stack[#stack]
	key = key or #target+1
	target[key],pack = pack,target
	stack[#stack] = nil
end

]]		

gen.postamble = [[

return pack
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
	return fn.."(fd, "..args..")"
end

--	atom:
--		pack[#pack+1] = <<type>>(fd, <<args>>)
function gen.atom(token)
	local fn = token[1]
	local args = token[2]:gsub('%.', ', ')
	return "pack[#pack+1] = "..fn.."(fd, "..args..")"
end

--	table:
--		push()
--		<<table contents>>
--		pop()
function gen.table(token)
	return "pop()\n"
	..parse(token[1]:sub(2,-2))
	.."push()\n"
end

--	group:
--		<<group contents>>
function gen.group(token)
	return parse(token[1]:sub(2,-2))
end

function gen.name_atom(token)
	local fn = token[2]
	local args = token[3]:gsub('%.', ', ')
	return "pack."..token[1].." = "..fn.."(fd, "..args..")"
	
end

function gen.name_table(token)
	return "pop()\n"
	..parse(token[2]:sub(2,-2))
	.."push("..token[1]..")\n"
end

function gen.prerepeat(token, get)
	local next = get()
	local src = gen[next.type](next)
	
	return "for i=1,"..token[1].." do\n\n"..src.."\nend"
end

function gen.postrepeat(token,get, asl)
	local src = table.remove(asl)
	
	return "for i=1,"..token[1].." do\n\n"..src.."\nend"
end

return gen

