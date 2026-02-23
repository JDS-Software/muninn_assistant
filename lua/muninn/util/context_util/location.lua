local M = {}
---@class MnLocation
---@field sRow number
---@field sCol number
---@field eRow number
---@field eCol number
local MnLocation = {}
MnLocation.__index = MnLocation

---@return string
function MnLocation:to_string()
    return vim.json.encode(self)
end

---@param node TSNode
---@return MnLocation
function M.new(node)
    local sRow, sCol = node:start()
    local eRow, eCol = node:end_()
    local self = setmetatable({ sRow = sRow, sCol = sCol, eRow = eRow, eCol = eCol }, MnLocation)
    return self
end

return M
