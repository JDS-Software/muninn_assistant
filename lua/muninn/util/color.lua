local M = {}

---@param x number
---@return number x rounded up or down (up at x.5)
local function round(x)
    return math.floor(x + 0.5)
end

---@class MnColor
---@field r number proportion of red 0 to 1
---@field g number proportion of green 0 to 1
---@field b number proportion of blue 0 to 1
local MnColor = {}
MnColor.__index = MnColor

---@return MnColorGradientFn
function MnColor:to_grad()
    ---@param _ number
    ---@return MnColor
    return function(_)
        return vim.deepcopy(self)
    end
end

---@param target_color MnColor the color to move towards
---@param x number the proportion of motion. i.e. 0.1 would be 10% of the distance between self and target_color
---@return MnColor resulting color
function MnColor:lerp(target_color, x)
    x = math.max(0, math.min(1, x))
    local new_r = self.r + (target_color.r - self.r) * x
    local new_g = self.g + (target_color.g - self.g) * x
    local new_b = self.b + (target_color.b - self.b) * x
    return M.new_color(new_r, new_g, new_b)
end

function MnColor.__tostring(self)
    return string.format("#%02x%02x%02x", round(255 * self.r), round(255 * self.g), round(255 * self.b))
end

---@param r number red 0.0 to 1.0 value
---@param g number green 0.0 to 1.0 value
---@param b number blue 0.0 to 1.0 value
function M.new_color(r, g, b)
    return setmetatable({
        r = math.max(0, math.min(1, r)),
        g = math.max(0, math.min(1, g)),
        b = math.max(0, math.min(1, b)),
    }, MnColor)
end

---@param r number red 0 to 255 value
---@param g number green 0 to 255 value
---@param b number blue 0 to 255 value
function M.new_color_rgb(r, g, b)
    return M.new_color(r / 255.0, g / 255.0, b / 255.0)
end

---@param str string hex string for color
---@return MnColor
function M.new_color_from_hex(str)
    str = str:gsub("^#", "")

    if #str ~= 3 and #str ~= 6 then
        error("Invalid hex color string: must be 3 or 6 hex digits (with optional leading #)")
    end

    if not str:match("^%x+$") then
        error("Invalid hex color string: contains non-hexadecimal characters")
    end

    local r, g, b

    if #str == 3 then
        r = tonumber(str:sub(1, 1) .. str:sub(1, 1), 16)
        g = tonumber(str:sub(2, 2) .. str:sub(2, 2), 16)
        b = tonumber(str:sub(3, 3) .. str:sub(3, 3), 16)
    else
        r = tonumber(str:sub(1, 2), 16)
        g = tonumber(str:sub(3, 4), 16)
        b = tonumber(str:sub(5, 6), 16)
    end

    return M.new_color_rgb(r, g, b)
end

---@alias MnColorGradientFn fun(number): MnColor

---@param start_color MnColor
---@param end_color MnColor
---@return MnColorGradientFn
function M.new_linear_gradient(start_color, end_color)
    ---@param x number 0 to 1
    return function(x)
        local proportion = math.max(0, math.min(x, 1))
        return start_color:lerp(end_color, proportion)
    end
end

---@param start_color MnColor starting color. x = 0 results in 100% start_color
---@param intermed_color MnColor starting color. x = 0.5 results in 100% intermed_color
---@param end_color MnColor ending color. x = 1 results in 100% end_color
---@return MnColorGradientFn
function M.new_triangular_gradient(start_color, intermed_color, end_color)
    ---@param x number value from 0 to 1 representing the location along the spectrum from start to end
    ---@return MnColor
    return function(x)
        if x < 0.5 then
            local t = x * 2 -- Scale x from [0, 0.5] to [0, 1]
            return start_color:lerp(intermed_color, t)
        else
            local t = (x - 0.5) * 2 -- Scale x from [0.5, 1] to [0, 1]
            return intermed_color:lerp(end_color, t)
        end
    end
end

M.muninn_background = M.new_color_from_hex("#1e1e2e")
M.muninn_blue = M.new_color_from_hex("#4c4c74")
M.muninn_blue_saturated = M.new_color_from_hex("#2f2f96")
M.muninn_orange = M.new_color_from_hex("#b57c0e")
M.muninn_orange_saturated = M.new_color_from_hex("#ec7c0e")
M.cream = M.new_color_from_hex("#f0e9cc")
M.black = M.new_color(0, 0, 0)
M.white = M.new_color(1, 1, 1)
M.red = M.new_color(1, 0, 0)
M.green = M.new_color(0, 1, 0)
M.blue = M.new_color(0, 0, 1)
M.grey = M.new_color(0.5, 0.5, 0.5)

function M.get_theme_background()
    local normal_hl = vim.api.nvim_get_hl(0, { name = "Normal" })
    local bg_color = normal_hl.bg

    if not bg_color then
        -- Fallback to default background if Normal highlight doesn't have bg set
        return M.muninn_background
    end

    -- Convert decimal color value to RGB components
    local r = math.floor(bg_color / 65536) % 256
    local g = math.floor(bg_color / 256) % 256
    local b = bg_color % 256

    return M.new_color_rgb(r, g, b)
end

--- prebaked gradients
M.text_gradient = M.new_triangular_gradient(M.muninn_orange, M.muninn_orange_saturated, M.muninn_orange)
return M
