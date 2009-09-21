local lexis = {}

local function lexeme(name)
	return function(pattern)
		lexis[#lexis+1] = { name=name, pattern="^"..pattern }
	end
end

lexeme (false) 		"%s+"	-- whitespace
lexeme (false)      "%-%-[^\n]*" -- comments
lexeme "control"	"([-+@<>=])"
lexeme "name"       "([%a_][%a_.]*)"
lexeme "number"     "(%d+)"
lexeme "{"          "%{"
lexeme "}"          "%}"
lexeme "("          "%("
lexeme ")"          "%)"
lexeme ":"          "%:"
lexeme "*"          "%*"

return function(source)
	local orig = source
	local index = 1
    
    local function where()
        return ("character %d ('%s')."):format(index, source:sub(1,4))
    end
    
    local function find_match()
        for _,lexeme in ipairs(lexis) do
            if source:match(lexeme.pattern) then
                return lexeme,select(2, source:find(lexeme.pattern))
            end
        end
        error (("Lexical error in format string at %s."):format(where()))
    end
    
    local function eat_whitespace()
        if #source == 0 then return end
        local match,size = find_match()
        
        if not match.name then
            source = source:sub(size+1, -1)
            index = index + size
            return eat_whitespace()
        end
    end
    
    local function next()
        eat_whitespace()
        
    	if #source == 0 then return nil end

        local lexeme,size,text = find_match()

        source = source:sub(size+1, -1)
        index = index+size
         
--                print(lexeme.name, debug.traceback())
        return { text = text, type = lexeme.name }
    end
    
    local function peek()
        eat_whitespace()
        
    	if #source == 0 then return nil end

        local lexeme,size,text = find_match()
         
--                print(lexeme.name, debug.traceback())
        return { text = text, type = lexeme.name }
    end
        
	return {
        next = next;
        peek = peek;
        where = where;
        tokens = function() return next end;
    }
end

