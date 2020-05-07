-- regression tests for vstruct
-- tests for fixed bugs go here to make sure they don't recur
-- tests are named after the bug they trigger, not the intended behaviour

local test = require "vstruct.test.common"
local frexp = require "vstruct.frexp"

-- No point in running these tests if there isn't a builtin frexp to compare to.
if not math.frexp then return end

test.group "frexp()"

local function test_frexp(x)
  local m,e = math.frexp(x)
  if m >= 1 or m <= -1 then
    -- At least on my machine, frexp() sometimes returns 1 as the mantissa, in
    -- violation as the spec. Correct this so that we can more properly compare
    -- things.
    m,e = m/2, e+1
  end
  local m2,e2 = frexp(x)
  local ok = m == m2 and e == e2
  test.record("frexp equivalence", ok, x,
    "(builtin) %f,%f != %f,%f (lua)", m, e, m2, e2)
end

local inf = math.huge
local z = 0.0
local nz = -z
local doubles = {
  0.0, 1.0, 2.0,
  1/2, 1/4, 1/8,
  4.9406564584124654418e-324,
  7.4169128616906696301e-309,
  1.483382572338133926e-308,
  2.225073858507200889e-308,
  2.2250738585072013831e-308,
  2.2250738585072018772e-308,
  2.9667651446762683461e-308,
  3.7084564308453353091e-308,
  4.4501477170144022721e-308,
  8.9884656743115795386e+307,
  8.9884656743115815345e+307,
  1.1984620899082105386e+308,
  1.4980776123852631234e+308,
  1.7976931348623157081e+308,
  4.9406564584124654418e-324,
  2.225073858507200889e-308,
  2.2250738585072013831e-308,
  1.7976931348623157081e+308,
  0.0,
  nz,
  -4.9406564584124654418e-324,
  -7.4169128616906696301e-309,
  -1.483382572338133926e-308,
  -2.225073858507200889e-308,
  -2.2250738585072013831e-308,
  -2.2250738585072018772e-308,
  -2.9667651446762683461e-308,
  -3.7084564308453353091e-308,
  -4.4501477170144022721e-308,
  -8.9884656743115795386e+307,
  -8.9884656743115815345e+307,
  -1.1984620899082105386e+308,
  -1.4980776123852631234e+308,
  -1.7976931348623157081e+308,
  -4.9406564584124654418e-324,
  -2.225073858507200889e-308,
  -2.2250738585072013831e-308,
  -1.7976931348623157081e+308,
  nz,
}

for _,double in ipairs(doubles) do
  test_frexp(double)
end
