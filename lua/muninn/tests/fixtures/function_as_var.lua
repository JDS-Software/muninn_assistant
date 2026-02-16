local M = {}

-- This comment isn't captured
M.example = function()
	print([[
    This only matches through the anonymous function body.
    It doesn't capture the name or the comment above when detecting the scope.
        ]])
end

-- This comment is captured
function M.working()
	print("This matches correctly")
end

return M
