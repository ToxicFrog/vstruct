local ast = {}

function ast.List()
    local child = { width = 0 }
    local List = { width = 0, child }
    
    function List:append(node)
        if node.width then
            if not child then
                child = { width = 0 }
                self[#self+1] = child
            end
            
            if self.width then
                self.width = self.width + node.width
            end
            
            child[#child+1] = node
            child.width = child.width + node.width
        else
            child = nil
            self.width = nil
            self[#self+1] = node
        end
    end
    
    return List
end

function ast.IO(name, width)
    width = tonumber(width.text)
    
    -- FIXME validate width
    
    return {
        tag = "io";
        width = width;
        type = name;
    }
end

function ast.Name(key, value)
    return {
        tag = "name";
        width = value.width;
        key = key;
        value = value;
    }
end

function ast.Repeat(count, value)
    return {
        tag = "repeat";
        width = (value.width and count * value.width) or nil;
        count = count;
        value = value;
    }
end

function ast.parse(source)
    local lex = require "struct.lexer" (source)
    local root = ast.List()
    
    for node in (function() return ast.next(lex) end) do
        root:append(node)
    end
    
    return root
end

function ast.name(lex)
    local name = lex.next().text
    local next = lex.next()
    
    if next.type == "number" then
        return ast.IO(name, next)
        
    elseif next.type == ":" then
        next = ast.next(lex)
        if next.tag == "io" or next.tag == "table" then
            return ast.Name(name, next)
        else
            ast.error(lex, "value (field or table)")
        end
    end
    
    ast.error(lex, "number or ':'")
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
    
    elseif tok.type == "name" then
        return ast.name(lex)
    
    elseif tok.type == "number" then
        -- it's either a repeat or a bitpack
        return ast.repeat_or_bitpack(lex)
        
    elseif tok.type == "control" then
        return ast.control(lex)
        
    else
        ast.error(lex, "'(', '{', name, number, control, or io specifier")
    end
end

function ast.repeat_or_bitpack(lex)
    local count = tonumber(lex.next().text)
    local next = lex.next()
    
    -- is it a repeat?
    if next.type == "*" then
        next = ast.next(lex)
        return ast.Repeat(count, next)
    
    else
        ast.error(lex, "* (bitpacks not supported yet)")
    end
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
    
    local group = ast.List()
    group.tag = "table"
    
    while lex.peek().type ~= '}' do
        group:append(ast.next(lex))
    end
    
    ast.require(lex, '}')
    return group
end

function ast.require(lex, type)
    local t = lex.next()
    
    if t.type ~= type then
        ast.error(lex, type)
    end
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