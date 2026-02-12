local M = {}
local location = require("muninn.util.context_util.location")

---@class MnReference
---@field node TSNode
---@field loc MnLocation
local MnReference = {}
MnReference.__index = MnReference

---@param node TSNode
---@return MnReference
function M.new(node)
    local self = setmetatable({ node = node, loc = location.new(node) }, MnReference)
    return self
end

return M
