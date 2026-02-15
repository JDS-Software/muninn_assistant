local M = {}
local logger = require("muninn.util.log").default

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

---@alias MnColorGradientFn fun(MnColor, MnColor, number): number

---@param start_color MnColor starting color. x = 0 results in 100% start
---@param end_color MnColor ending color. x = 1 results in 100% end
---@param x number value from 0 to 1 representing the location along the spectrum from start to end
---@return MnColor
M.gradient_linear = function(start_color, end_color, x) --[[@as MnColorGradientFn]]
	x = math.max(0, math.min(1, x))

	local r = start_color.r + (end_color.r - start_color.r) * x
	local g = start_color.g + (end_color.g - start_color.g) * x
	local b = start_color.b + (end_color.b - start_color.b) * x

	return M.new_color(r, g, b)
end

---@param intermed_color MnColor starting color. x = 0 results in 100% start
---@return MnColorGradientFn
function M.gradient_triangular(intermed_color)
	---
	---@param start_color MnColor starting color. x = 0 results in 100% start
	---@param end_color MnColor ending color. x = 1 results in 100% end
	---@param x number value from 0 to 1 representing the location along the spectrum from start to end
	return function(start_color, end_color, x)
		x = math.max(0, math.min(1, x))

		if x < 0.5 then
			local t = x * 2 -- Scale x from [0, 0.5] to [0, 1]
			return M.gradient_linear(start_color, intermed_color, t)
		else
			local t = (x - 0.5) * 2 -- Scale x from [0.5, 1] to [0, 1]
			return M.gradient_linear(intermed_color, end_color, t)
		end
	end
end

---@return MnColor

M.muninn_background = M.new_color_from_hex("#1e1e2e")
M.muninn_blue = M.new_color_from_hex("#4c4c74")
M.muninn_orange = M.new_color_from_hex("#b57c0e")
M.muninn_orange_saturated = M.new_color_from_hex("#ec7c0e")
M.cream = M.new_color_from_hex("#f0e9cc")
M.black = M.new_color(0, 0, 0)
M.white = M.new_color(1, 1, 1)
M.red = M.new_color(1, 0, 0)
M.grey = M.new_color(0.5, 0.5, 0.5)

function M.get_theme_background()
	local normal_hl = vim.api.nvim_get_hl(0, { name = "Normal" })
	local bg_color = normal_hl.bg

	if not bg_color then
		-- Fallback to default background if Normal highlight doesn't have bg set
		return M.muninn_background
	end
	logger():log("INFO", vim.inspect(normal_hl))

	-- Convert decimal color value to RGB components
	local r = math.floor(bg_color / 65536) % 256
	local g = math.floor(bg_color / 256) % 256
	local b = bg_color % 256

	return M.new_color_rgb(r, g, b)
end

-- Gradients
M.gradient_thru_black = M.gradient_triangular(M.black)
M.gradient_thru_white = M.gradient_triangular(M.white)
return M
