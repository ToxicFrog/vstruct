-- we need to test all the different formats, at minimum
-- this means bimPpsuxz for now
-- Copyright © 2008 Ben "ToxicFrog" Kelly; see COPYING

local name = (...):gsub('%.[^%.]+$', '')
local struct = require(name)

local function test(exp, expected, name)
	print(name, tostring(expected):sub(1,7), exp and "PASS" or "FAIL", exp and "" or val)
end

local function check_bm(m)
	return m[8] and m[7] and m[6] and m[5]
	and m[4] and not m[3] and m[2] and not m[1]
end

data = "\1"
	.."\254\255\255"
	.."\250"
	.."\1\128".."\2\192"
	.."foo"
	.."\100\0\0"
	.."\0\0\0\0\0\0\0"
	.."bar baz\0\0\0".."moby\0"

unpacked = struct.unpack(data, "< b1 i3 m1 > (P8.8) * 1 p1.1 < 1 * (s3 u3) x7 z10 z")

test(unpacked[1] == true,		true,		"b")
test(unpacked[2] == -2, 		-2, 		"i")
test(check_bm(unpacked[3]),		true, 		"m")
test(unpacked[4] == 1.5,		1.5,		"P")
test(unpacked[5] == 2.75,		2.75,		"p")
test(unpacked[6] == "foo",		"foo",		"s")
test(unpacked[7] == 100,		100,		"u")
test(unpacked[8] == "bar baz",	"bar baz",	"z")
test(unpacked[9] == "moby", 	"moby", 	"z")

packed = struct.pack("< b1 i3 m1 > P8.8 p1.1 < s3 u3 x7 z10 z", unpacked)
test(packed, data, "r/w")

os.exit(0)
