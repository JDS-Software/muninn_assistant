local M = {}
local logger = require("muninn.util.log").default

local BASE_CHAR = 0x2800

local function mask_to_codepoint(mask)
    local least = bit.band(mask, 0b111)
    local least_nib = bit.band(mask, 0b1000)
    -- the most significant bit in the nibble needs to go to index 7
    least_nib = bit.lshift(least_nib, 3)
    local great = bit.band(mask, 0b1110000)
    -- the top nibble's bottom 3 bits need to move down
    great = bit.rshift(great, 1)
    local great_nib = bit.band(mask, 0b10000000)
    return vim.fn.nr2char(BASE_CHAR + bit.bor(least, least_nib, great, great_nib), true)
end

---@param byte table<integer>
local function anneal_byte(byte)
    return bit.bor(
        byte[5],
        bit.lshift(byte[6], 1),
        bit.lshift(byte[7], 2),
        bit.lshift(byte[8], 3),
        bit.lshift(byte[1], 4),
        bit.lshift(byte[2], 5),
        bit.lshift(byte[3], 6),
        bit.lshift(byte[4], 7)
    )
end

---@class MnFrame
---@field width integer
---@field height integer
---@field bits table<integer>
local MnFrame = {}
MnFrame.__index = MnFrame

---@return table<integer>
function MnFrame:_to_bytes()
    local bytes = {}
    local row_stride = 4
    local col_stride = 2
    -- Tile 2x4 kernels: 4 rows tall, 2 columns wide.
    -- Each kernel produces one byte: left col rows 0-3 → bits 0-3, right col rows 0-3 → bits 4-7.
    for row = 1, self.height, row_stride do
        for col = 1, self.width, col_stride do
            local b = { 0, 0, 0, 0, 0, 0, 0, 0 }
            for r = 0, row_stride - 1 do
                local base = (row - 1 + r) * self.width
                b[r + 1] = self.bits[base + col + 1] or 0
                b[r + 5] = self.bits[base + col] or 0
            end
            bytes[#bytes + 1] = anneal_byte(b)
        end
    end
    return bytes
end

---@return table<string>
function MnFrame:to_lines()
    local results = {}
    local stride = self.width / 2
    local bytes = self:_to_bytes()
    for i = 1, #bytes, stride do
        local chars = {}
        for j = 0, stride - 1 do
            chars[j + 1] = mask_to_codepoint(bytes[i + j])
        end
        results[#results + 1] = table.concat(chars)
    end
    return results
end

---@param bits table<integer>
---@param width integer
---@param height integer
function M.new_frame(bits, width, height)
    if width % 4 ~= 0 then
        error("frame width must be multiple of 4, got " .. width, 2)
    end
    if height % 4 ~= 0 then
        error("frame height must be multiple of 4, got " .. height, 2)
    end
    local len = width * height
    if len ~= #bits then
        error("bits length must be width x height (" .. len .. "), got " .. #bits, 2)
    end
    return setmetatable({ bits = bits, width = width, height = height }, MnFrame)
end

return M
