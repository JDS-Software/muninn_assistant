local M = {}
local time = require("muninn.util.time")
local color = require("muninn.util.color")
local logger = require("muninn.util.log").default

M.looper = vim.fn.split("⠛⠹⢸⣰⣤⣆⡇⠏", "\\zs")
M.sandpile = vim.fn.split(
	"⢀⢀⢀⢀⣀⣀⣀⣀⣠⣠⣠⣠⣤⣤⣤⣤⣴⣴⣴⣴⣶⣶⣶⣶⣾⣾⣾⣾⣿⣿⣿⣿⣿⣿⣶⣶⣶⣶⣤⣤⣤⣤⣀⣀⣀⢀⢀      ",
	"\\zs"
)
M.crawler = vim.fn.split("⢀⣀⣠⣤⣴⣶⣾⣿⡿⠿⠟⠛⠋⠉⠁", "\\zs")
M.spinner = vim.fn.split("⠙⠸⢰⣠⣄⡤⢤⣠⣄⡆⠇⠋⠙⠚⠓⠋", "\\zs")
M.reverse_spinner = vim.fn.split("⠋⠓⠚⠙⠋⠇⡆⣄⣠⢤⡤⣄⣠⢰⠸⠙", "\\zs")
M.blackbird_icon = "\xf0\x9f\x90\xa6\xe2\x80\x8d\xe2\xac\x9b"

---@class MnAnimation
---@field t_start MnTime
---@field target_fps number
---@field frame_number number
---@field banner string
---@field outer_animation table animation characters
---@field inner_animation table animation characters
---@field fg_start MnColor
---@field fg_end MnColor?
---@field bg_start MnColor
---@field bg_end MnColor?
---@field duration MnTime
---@field oscillator MnOscillator
local MnAnimation = {}
MnAnimation.__index = MnAnimation

---@return number ms_to_wait
function MnAnimation:get_wait()
	return 1000 / self.target_fps
end

--- this will increment the internal frame state by 1
function MnAnimation:frame()
	self.frame_number = self.frame_number + 1
end

function MnAnimation:message()
	local outer_anim_idx = (self.frame_number % #self.outer_animation) + 1
	local inner_anim_idx = (self.frame_number % #self.inner_animation) + 1
	logger():log("INFO", string.format("outer_anim_idx: %d, inner_anim_idx: %d", outer_anim_idx, inner_anim_idx))
	logger():log("INFO", vim.inspect(self))
	return self.outer_animation[outer_anim_idx]
		.. M.blackbird_icon
		.. self.inner_animation[inner_anim_idx]
		.. " "
		.. self.banner
		.. " "
		.. self.inner_animation[inner_anim_idx]
		.. M.blackbird_icon
		.. self.outer_animation[outer_anim_idx]
end

function MnAnimation:get_hl()
	local fg, bg
	local t = time.new_time()
	local t_diff = t:diff(self.t_start)
	if self.fg_start and self.fg_end then
		fg = color.gradient(self.fg_start, self.fg_end, self.oscillator:at(t_diff))
	elseif self.fg_start then
		fg = self.fg_start
	else
		fg = color.black
	end
	if self.bg_start and self.bg_end then
		bg = color.gradient(self.bg_start, self.bg_end, self.oscillator:at(t_diff))
	elseif self.bg_start then
		bg = self.bg_start
	else
		bg = color.white
	end
	return { fg = tostring(fg), bg = tostring(bg) }
end

---Creates a new animation instance with the specified parameters
---@param banner string The text to display in the center of the animation
---@param outer_animation table Array of animation characters for outer animation
---@param inner_animation table Array of animation characters for inner animation
---@param fg_start MnColor Starting foreground color
---@param bg_start MnColor Starting background color
---@param duration MnTime Duration of the animation cycle
---@return MnAnimation
local function new_animation(banner, outer_animation, inner_animation, fg_start, bg_start, duration)
	return setmetatable({
		t_start = time.new_time(),
		banner = banner,
		inner_animation = inner_animation,
		outer_animation = outer_animation,
		fg_start = fg_start,
		bg_start = bg_start,
		target_fps = 24,
		frame_number = 0,
		duration = duration,
		oscillator = time.new_oscillator(duration),
	}, MnAnimation)
end

---@return MnAnimation
function M.new_autocomplete_animation()
	local anim =
		new_animation(" Muninn Autocompleting ", M.spinner, M.sandpile, color.black, color.cream, time.new_time(4))
	anim.fg_end = color.muninn_blue
	anim.target_fps = 10
	return anim
end

return M
