-- regression tests for vstruct
-- tests for fixed bugs go here to make sure they don't recur
-- tests are named after the bug they trigger, not the intended behaviour

local test = require "vstruct.test.common"

local x = test.x
local T = test.autotest

test.group "regression tests"

-- B#21
-- this was found as an error in writing fixed point values, but is actually an underlying issue
-- with how u and i handle non-integer inputs
-- in short: don't assume string.char() truncates, because it doesn't.
T("i rounds instead of truncating",
  "> i2",
  x"FF FF", -1.5,
  x"FF FF", -1)
T("u rounds instead of truncating",
  "> u2",
  x"00 01", 1.5,
  x"00 01", 1)
T("p passes invalid value to string.char and crashes",
  "> p2,2",
  x"FD 00", -192.098910,
  x"FD 00", -192.00)

-- math.frexp() replacement for Lua 5.3 when compiled without LUA_COMPAT_MATHLIB.
-- Work in progress; fails on very large/small numbers because 2^e ends up being
-- inf/0 in the final calculation of (x/2^e).
local abs,floor,log = math.abs,math.floor,math.log
local log2 = log(2)
local function frexp(x)
  if x == 0 then return 0, 0 end
  local e = floor(log(abs(x)) / log2 + 1)
  return x / 2 ^ e, e
end

local function test_frexp(x)
  local m,e = math.frexp(x)
  local m2,e2 = frexp(x)
  test.record("frexp equivalence", m == m2 and e == e2, x,
    "(builtin) %f,%f != %f,%f (lua)", m, e, m2, e2)
end

-- test_frexp(1.7976931348623157081e+308)
-- test_frexp(-1.7976931348623157081e+308)
-- test_frexp(1.7976931348623157081e-308)
-- test_frexp(-1.7976931348623157081e-308)
