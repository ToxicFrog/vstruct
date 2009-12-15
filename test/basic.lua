-- we need to test all the different formats, at minimum
-- this means bimPpsuxz for now
-- Copyright � 2008 Ben "ToxicFrog" Kelly; see COPYING

-- test cases
-- simple: read and write of each format, seeks, endianness controls
-- complex: naming, tables, repetition, combinations of all of these,
--		nested tables, multi formats per string
-- non-obvious: seek past end of file
-- error handling: seek past start, read past end, invalid widths,
--		non-isomorphic input tables

require "util"

local c = string.char
local require,math,ipairs,string,tostring,print,os,pairs,unpack,table
	= require,math,ipairs,string,tostring,print,os,pairs,unpack,table

module((...))
local struct = require(_NAME:match("^[^%.]+"))
local name = (...):gsub('%.[^%.]+$', '')

local function check_bm(m)
    return m[8] and m[7] and m[6] and m[5]
	and m[4] and not m[3] and m[2] and not m[1]
end

local tests = {
    -- booleans
    { raw = "\0\0\0\0\0\0\0\1"; format = "> b8"; val = true; },
    --	{ raw = "\1\0\0\0\0\0\0\0"; format = "(b8)*1"; val = true; },
    { raw = "\0\0\0\0\0\0\0\0"; format = "1*(b8)"; val = false; },
    -- unsigned integers
    { raw = "\254\255\255"; format = "< u3"; val = 2^24-2; },
    -- signed integers
    { raw = "\254\255\255"; format = "< i3"; val = -2 },
    -- plain strings
    { raw = "foobar"; format = "s4"; val = "foob"; },
    -- counted strings
    { raw = "\006\000\000\000foobar"; format = "< c4"; val = "foobar"; },
    -- null terminated strings
    { raw = "foobar\0baz"; format = "z"; val = "foobar"; },
    { raw = "foobar\0baz"; format = "z10"; val = "foobar"; },
    -- bitmasks
    { raw = "\250"; format = "m1"; test = check_bm; },
    -- skip/pad
    { raw = "\0\0\0\0\2"; format = "x4u1"; val = 2 },
    -- seek
    { raw = "\0\0\2\0\0"; format = "@2 u1 x2"; val = 2 },
    { raw = "\0\0\2\0\0"; format = "+2 u1 x2"; val = 2 },
    { raw = "\0\0\2\0\0"; format = "+4 -2 u1 x2"; val = 2 },
    -- endianness
    { raw = "\0\1"; format = "< u2"; val = 256 },
    { raw = "\0\1"; format = "> u2"; val = 1 },
    { raw = "\1\1"; format = "= u2"; val = 257 },
    -- bitpacks
    { raw = c(0x0F, 0x00); format = "< [2| x4 u4 x8]"; val = 0 },
    { raw = c(0x0F, 0x00); format = "< [2| u4 x12]"; val = 15 },
    { raw = c(0x0F, 0x00); format = "> [2| x8 u4 x4]"; val = 15 },
    { raw = c(0x0F, 0x00); format = "< [2| i4 x12]"; val = -1 },
    { raw = c(0x0F, 0x00); format = "> [2| x8 i4 x4]"; val = -1 },
    { raw = c(0xF0); format = "[1| x4 b4]"; val = true },
    { raw = c(0x00); format = "[1| x4 b4]"; val = false },
    { raw = c(0x0F,0xA0); format = "> [2| x4 m8 x4]"; test = check_bm },
    -- FIXME - names
    -- FIXME - tables
    -- FIXME - repetition
    -- fixed point
    { raw = "\1\128"; format = "> p8,8"; val = 1.5; },
    { raw = "\2\192"; format = "> p8,8"; val = 2.75; },
    -- floats
    { raw = c(0x00, 0x00, 0x00, 0x00); format = "< f4"; val = 0.0; },
    { raw = c(0x3f, 0x80, 0x00, 0x00); format = "> f4"; val = 1.0; },
    { raw = c(0x00, 0x00, 0x80, 0x3f); format = "< f4"; val = 1.0; },
    { raw = c(0x00, 0x00, 0x80, 0xbf); format = "< f4"; val = -1.0; },
    { raw = c(0x00, 0x00, 0x80, 0x7f); format = "< f4"; val = math.huge; },
    { raw = c(0x00, 0x00, 0x80, 0xff); format = "< f4"; val = -math.huge; },
    { raw = c(0x00, 0x00, 0xc0, 0x7f); format = "< f4"; val = 0/0; test = function(v) return v ~= v end },
    { raw = c(0x00, 0x00, 0xc0, 0xff); format = "< f4"; val = 0/0; test = function(v) return v ~= v end },
    -- doubles
    { raw = c(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00); format = "< f8"; val = 0.0; },
    { raw = c(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf0, 0x3f); format = "< f8"; val = 1.0; },
    { raw = c(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf0, 0xbf); format = "< f8"; val = -1.0; },
    { raw = c(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf0, 0x7f); format = "< f8"; val = math.huge; },
    { raw = c(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf0, 0xff); format = "< f8"; val = -math.huge; },
    { raw = c(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf8, 0x7f); format = "< f8"; val = 0/0; test = function(v) return v ~= v end },
    { raw = c(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf8, 0xff); format = "< f8"; val = 0/0; test = function(v) return v ~= v end },
}

function od(str)
    return str:gsub('.', function(c) return string.format("%02X ", c:byte()) end)
end

function check(test)
    local val, pass, raw
    local fmt = "%16.16s %33.33s%2.2s %17.17s %4.4s %3.3s"

    val = struct.unpack(test.format, test.raw)[1]
    pass = test.test
        and test.test(val)
        or val == test.val
    print(fmt:format(test.format, od(test.raw), "=>", tostring(val), pass and "PASS" or "FAIL", pass and "" or "!!!"):sub(1,79))
    if not pass then return end

    raw = struct.pack(test.format, {val})
    pass = raw == test.raw
    -- if we have a failure, it might be because there are multiple valid on-disk forms
    -- for example, a boolean can be any non-zero value, but we always write it back out as 1
    -- so, re-read it using the same format and see if it matches
    if not pass then
        local new_val = struct.unpack(test.format, raw)[1]
        pass = test.test and test.test(val) or new_val == test.val
    end

    print(fmt:format(test.format, od(raw), "<=", tostring(val), pass and "PASS" or "FAIL", pass and "" or " !!!"):sub(1,79))
end

struct.unpack('< @0 u4 m4 @4 { u4 u4 } @8 foo:{ z4 z4 i4 } 4*(u6)', string.rep('-', 100))

for i,test in ipairs(tests) do
    check(test)
end

os.exit(0)
