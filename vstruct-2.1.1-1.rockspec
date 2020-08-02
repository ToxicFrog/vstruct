package = "vstruct"
version = "2.1.1-1"
source = {
   url = "git+https://github.com/ToxicFrog/vstruct.git",
   tag = "v2.1.1"
}
description = {
   summary = "Lua library to manipulate binary data",
   homepage = "https://github.com/ToxicFrog/vstruct",
}
dependencies = {
  "lua >= 5.1, <= 5.4"
}
build = {
   type = "builtin",
   modules = {
      ["vstruct.api"] = "api.lua",
      ["vstruct.ast"] = "ast.lua",
      ["vstruct.ast.Bitpack"] = "ast/Bitpack.lua",
      ["vstruct.ast.IO"] = "ast/IO.lua",
      ["vstruct.ast.List"] = "ast/List.lua",
      ["vstruct.ast.Name"] = "ast/Name.lua",
      ["vstruct.ast.Node"] = "ast/Node.lua",
      ["vstruct.ast.Repeat"] = "ast/Repeat.lua",
      ["vstruct.ast.Root"] = "ast/Root.lua",
      ["vstruct.ast.Table"] = "ast/Table.lua",
      ["vstruct.compat1x"] = "compat1x.lua",
      ["vstruct.cursor"] = "cursor.lua",
      ["vstruct.frexp"] = "frexp.lua",
      ["vstruct"] = "init.lua",
      ["vstruct.io"] = "io.lua",
      ["vstruct.io.a"] = "io/a.lua",
      ["vstruct.io.b"] = "io/b.lua",
      ["vstruct.io.bigendian"] = "io/bigendian.lua",
      ["vstruct.io.c"] = "io/c.lua",
      ["vstruct.io.defaults"] = "io/defaults.lua",
      ["vstruct.io.endianness"] = "io/endianness.lua",
      ["vstruct.io.f"] = "io/f.lua",
      ["vstruct.io.hostendian"] = "io/hostendian.lua",
      ["vstruct.io.i"] = "io/i.lua",
      ["vstruct.io.littleendian"] = "io/littleendian.lua",
      ["vstruct.io.m"] = "io/m.lua",
      ["vstruct.io.p"] = "io/p.lua",
      ["vstruct.io.s"] = "io/s.lua",
      ["vstruct.io.seekb"] = "io/seekb.lua",
      ["vstruct.io.seekf"] = "io/seekf.lua",
      ["vstruct.io.seekto"] = "io/seekto.lua",
      ["vstruct.io.u"] = "io/u.lua",
      ["vstruct.io.x"] = "io/x.lua",
      ["vstruct.io.z"] = "io/z.lua",
      ["vstruct.lexer"] = "lexer.lua",
   }
}
