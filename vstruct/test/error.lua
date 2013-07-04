-- FIXME - stuff still needing a test case:
-- * seek past end of file
-- * input table doesn't match format string
-- * format string is badly formed
-- * format string is semantically nonsensical (compile and runtime cases)

local test = require "vstruct.test.common"
local vstruct = require "vstruct"
local E = test.errortest

test.group "error conditions"


-- attempt to read/seek past bounds of file
-- seeking past the end is totally allowed when writing
-- when reading, you will get a different error when you try to do IO
E("invalid-seek-uf", "attempt to read past end of buffer", vstruct.unpack, "@8 u4", "1234")
E("invalid-seek-ub", "attempt to seek prior to start of file", vstruct.unpack, "@0 -4", "1234")
E("invalid-seek-pb", "attempt to seek prior to start of file", vstruct.pack, "@0 -4", "1234", {})

-- invalid argument type
E("invalid-arg-u1", "bad argument to vstruct API.*format string expected, got nil", vstruct.unpack)
E("invalid-arg-p1", "bad argument to vstruct API.*format string expected, got nil", vstruct.pack)
E("invalid-arg-c1", "bad argument to vstruct API.*format string expected, got nil", vstruct.compile)
E("invalid-arg-u1", "bad argument to vstruct API.*format string expected, got number", vstruct.unpack, 0, "1234")
E("invalid-arg-p1", "bad argument to vstruct API.*format string expected, got number", vstruct.pack, 0, {})
E("invalid-arg-c1", "bad argument to vstruct API.*format string expected, got number", vstruct.compile, 0)

E("invalid-arg-u2", "invalid fd argument to vstruct.unpack", vstruct.unpack, "@0", 0)
E("invalid-arg-p2", "invalid fd argument to vstruct.pack", vstruct.pack, "@0", 0, {})

E("invalid-arg-u3", "invalid data argument to vstruct.unpack", vstruct.unpack, "@0", "", "")
E("invalid-arg-p3", "invalid data argument to vstruct.pack", vstruct.pack, "@0", nil, "1234")

-- format string is ill-formed
-- format string is well-formed but nonsensical
    -- zero-length fields
    -- bitfield width doesn't match width of contents
    -- no support for format
-- input table doesn't match format string
