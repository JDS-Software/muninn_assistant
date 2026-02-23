-- Copyright (c) 2026-present JDS Consulting, PLLC.
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is furnished
-- to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.

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

---@param px number
---@param py number
function MnFrame:set_pixel(px, py)
    local col = math.floor(px + 0.5) + 1
    local row = math.floor(py + 0.5) + 1

    if col >= 1 and col <= self.width and row >= 1 and row <= self.height then
        local idx = (row - 1) * self.width + col
        self.bits[idx] = 1
    end
end

--- Midpoint circle algorithm (Bresenham's circle algorithm) handles circles with centers outside the frame
---@param center_x number x coordinate of the center, in pixels
---@param center_y number y coordinate of the center, in pixels
---@param radius number radius of the circle in pixels
function MnFrame:circle(center_x, center_y, radius)
    local x = radius
    local y = 0
    local decision = 1 - radius

    -- Draw 8 symmetric points for each (x, y) on the circle
    while x >= y do
        -- All 8 octants
        self:set_pixel(center_x + x, center_y + y)
        self:set_pixel(center_x + y, center_y + x)
        self:set_pixel(center_x - y, center_y + x)
        self:set_pixel(center_x - x, center_y + y)
        self:set_pixel(center_x - x, center_y - y)
        self:set_pixel(center_x - y, center_y - x)
        self:set_pixel(center_x + y, center_y - x)
        self:set_pixel(center_x + x, center_y - y)

        y = y + 1

        if decision <= 0 then
            decision = decision + 2 * y + 1
        else
            x = x - 1
            decision = decision + 2 * (y - x) + 1
        end
    end
end

---@param width integer
---@param height integer
---@param bits table<integer>?
---@return MnFrame
function M.new_frame(width, height, bits)
    if width % 4 ~= 0 then
        error("frame width must be multiple of 4, got " .. width, 2)
    end
    if height % 4 ~= 0 then
        error("frame height must be multiple of 4, got " .. height, 2)
    end
    local len = width * height
    if not bits then
        bits = {}
        for i = 1, len do
            bits[i] = 0
        end
    else
        if #bits ~= len then
            error("Provided bit array must have size " .. len .. "; got " .. #bits, 2)
        end
    end
    return setmetatable({ bits = bits, width = width, height = height }, MnFrame)
end

return M
