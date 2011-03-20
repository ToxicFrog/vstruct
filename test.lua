-- top-level test module for vstruct
-- run with 'lua test.lua' or, if vstruct is installed, with
-- 'lua -lvstruct.test -e ""'

-- Runs a "sensible default" set of tests against the vstruct module. Exits
-- cleanly if all of them passed; if any failed, reports the failed tests
-- on stdout and then raises an error.

local test = pcall(require, "vstruct.test.common")

-- maybe we aren't installed, and just need to deduce a custom package.path
-- from the location of this file
if not test then
    local libdir = arg[0]:gsub("[^/\\]+$", "").."../"
    package.path = package.path..";"..libdir.."?.lua;"..libdir.."?/init.lua"
    test = require "vstruct.test.common"
end

require "vstruct.test.basic"
require "vstruct.test.fp-bigendian"
require "vstruct.test.fp-littleendian"

if arg and #arg > 0 then
    require "vstruct.test.struct-test-gen"
else
    arg = { "NROF_TESTS=2^10", "read" }
    require "vstruct.test.struct-test-gen"
    package.loaded["vstruct.test.struct-test-gen"] = nil
    arg = { "NROF_TESTS=2^10", "write" }
    require "vstruct.test.struct-test-gen"
end

if test.report() > 0 then
    error("Some test cases failed; see preceding output for details.")
end
