local struct = require( (...):gsub("%.ast$","") )
local lexer = require( (...):gsub("%.ast$", ".lexer") )

local ast = {}
local cache = {}

for _,terminal in ipairs { "IO", "List", "Name", "Table", "Repeat", "Generator", "Root", "Bitpack" } do
    ast[terminal] = require ((...).."."..terminal)
end

function ast.parse(source)
    if struct.cache ~= nil and cache[source] then
        return cache[source]
    end

    local lex = lexer(source)
    local root = ast.Root(ast.List())
    
    for node in (function() return ast.next(lex) end) do
        root:append(node)
    end
    
    root = root:gen(ast.Generator())
    
    if struct.cache == true then
        cache[source] = root
    end
    
    return root
end

function ast.name(lex)
    local name = lex.next().text
    local next = lex.peek()
    
    if next and next.type == "number" and not lex.whitespace() then
        return ast.IO(name, lex.next().text)
    else
        return ast.IO(name, nil)
    end
end

function ast.key(lex)
    local name = lex.next().text
    local next = lex.peek()
    
    next = ast.next(lex)
    if next.tag == "io" or next.tag == "table" then
        return ast.Name(name, next)
    else
        ast.error(lex, "value (field or table)")
    end
end

function ast.next(lex)
    local tok = lex.peek()
    
    if not tok then
        return nil
    end
    
    if tok.type == '(' then
        return ast.group(lex)
    
    elseif tok.type == '{' then
        return ast.table(lex)
    
    elseif tok.type == '[' then
        return ast.bitpack(lex)
        
    elseif tok.type == "name" then
        return ast.name(lex)
    
    elseif tok.type == "key" then
        return ast.key(lex)
        
    elseif tok.type == "number" then
        return ast.repetition(lex)
        
    elseif tok.type == "control" then
        return ast.control(lex)
        
    else
        ast.error(lex, "'(', '{', name, number, control, or io specifier")
    end
end

function ast.repetition(lex)
    local count = tonumber(lex.next().text)
    ast.require(lex, "*");

    return ast.Repeat(count, ast.next(lex))
end

function ast.group(lex)
    ast.require(lex, '(')
    
    local group = ast.List()
    group.tag = "group"
    
    while lex.peek().type ~= ')' do
        group:append(ast.next(lex))
    end
    
    ast.require(lex, ')')
    return group
end

function ast.table(lex)
    ast.require(lex, '{')
    
    local group = ast.Table()
    
    while lex.peek().type ~= '}' do
        group:append(ast.next(lex))
    end
    
    ast.require(lex, '}')
    return group
end

function ast.bitpack(lex)
    ast.require(lex, "[")
    
    local bitpack = ast.Bitpack(tonumber(ast.require(lex, "number").text))
    
    ast.require(lex, "|")
    
    while lex.peek().type ~= "]" do
        bitpack:append(ast.next(lex))
    end
    
    ast.require(lex, "]")
    bitpack:finalize()
    return bitpack
end

function ast.require(lex, type)
    local t = lex.next()
    
    if t.type ~= type then
        ast.error(lex, type)
    end
    
    return t
end

function ast.error(lex, expected)
    error("vstruct: parsing format string at "..lex.where()..": expected "..expected..", got "..lex.peek().type)
end

return ast

--[[

format -> commands

command -> repeat | bitpack | group | named | value | control 

repeat -> NUMBER '*' command | command '*' NUMBER
bitpack -> NUMBER '|' commands '|'
group -> '(' commands ')'

named -> NAME ':' value
value -> table | primitive
table -> '{' commands '}'

primitive -> ATOM NUMBERS

control -> SEEK NUMBER | ENDIANNESS

--]]
