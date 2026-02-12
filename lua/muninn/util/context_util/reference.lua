local M = {}
local location = require("muninn.util.context_util.location")

---@class MnReference
---@field node TSNode
---@field loc MnLocation
local MnReference = {}
MnReference.__index = MnReference

---@param cursor table
---@return boolean
function MnReference:contains(cursor)
    local row = cursor[2]
    return self.loc.sRow + 1 <= row and row <= self.loc.eRow + 1
end

---@param node TSNode
---@return MnReference
function M.new(node)
    local self = setmetatable({ node = node, loc = location.new(node) }, MnReference)
    return self
end

return M
