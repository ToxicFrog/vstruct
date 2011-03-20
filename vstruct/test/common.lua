local vstruct = require "vstruct"

local char,ord = string.char,string.byte

local test = { results = {} }

function test.x(str)
	return (str:gsub("%X", ""):gsub("%x%x", function(b) return char(tonumber(b, 16)) end))
end

function test.od(str, sep)
	local fmt = "%02X"..(sep or " ")
    return (str:gsub('.', function(c) return fmt:format(c:byte()) end))
end

function test.eq(x, y)
	if type(x) ~= type(y) then return false end
	
	if type(x) == 'table' then
		for k,v in pairs(x) do
			if not test.eq(v, y[k]) then return false end
		end
		for k,v in pairs(y) do
			if not test.eq(v, x[k]) then return false end
		end
		return true
	end

	return x == y
end

function test.group(name)
	local group = { name=name }
	table.insert(test.results, group)
	test.current_group = group
end

-- record the results of the test
-- test is the name
-- result is the boolean pass/fail
-- message is an optional string, and will be displayed to the user as 
-- "note" or "fail" depending on the value of result
function test.record(name, result, data)
	table.insert(test.current_group, { name=name, result=result, message=message, data=data })
end

function test.autotest(name, format, buffer, data, output)
	local eq = test.eq
	local record = test.record
	
	output = output or buffer
	
	if type(data) ~= "table" then data = {data} end
	
	local unpacked = vstruct.unpack(format, buffer)
	local packed = vstruct.pack(format, unpacked)
	
	record(name.." (U )", eq(unpacked, data), unpack(unpacked))
	record(name.." (UP)", eq(packed, output), test.od(packed))

	local packed = vstruct.pack(format, data)
	local unpacked = vstruct.unpack(format, packed)
	
	record(name.." (P )", eq(packed, output), test.od(packed))
	record(name.." (PU)", eq(unpacked, data), unpack(unpacked))
end

function test.report()
    local allfailed = 0
	for _,group in ipairs(test.results) do
		local failed = 0
		print("\t=== "..group.name.." ===")

		for _,test in ipairs(group) do
		    if not test.result then
		        failed = failed + 1
		        print("FAIL", test.name)
		        if type(test.data) == 'string' and test.data:match("%z") then
		            print("", (test.data:gsub("%z", ".")))
		        else
		            print("",     test.data)
		        end
		    end
		end
		
		print("\tTotal: ", #group)
		print("\tFailed:", failed)
		print()
		allfailed = allfailed + failed
	end
	
	return allfailed
end

-- determine host endianness - HACK HACK HACK
function test.bigendian()
    return string.byte(string.dump(function() end)) == 0x00
end

return test
