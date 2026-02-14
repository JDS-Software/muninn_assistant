local M = {}
local color = require("muninn.util.color")
local logger = require("muninn.util.log").default
local time = require("muninn.util.time")

---@alias MnBanner fun(at_frame: number): string
---@alias MnAString fun(idx:number): string

local function to_astring(str)
	local backing = vim.fn.split(str, "\\zs")
	return function(idx)
		return backing[(idx % #backing) + 1] or ""
	end
end

local function to_double_wide_astring(stra, strb)
	local backinga = vim.fn.split(stra, "\\zs")
	local backingb = vim.fn.split(strb, "\\zs")
	return function(idx)
		local a = backinga[(idx % #backinga) + 1] or ""
		local b = backingb[(idx % #backingb) + 1] or ""
		return a .. b
	end
end

M.looper = to_astring("⠛⠹⢸⣰⣤⣆⡇⠏")
M.sandpile = to_astring("⢀⣀⣠⣤⣴⣶⣾⣿⣶⣤⣀⢀  ")
M.crawler = to_astring("⢀⣀⣠⣤⣴⣶⣾⣿⡿⠿⠟⠛⠋⠉⠁")
M.faller = to_astring("⠁⠉⠋⠛⠟⠿⡿⣿⣾⣶⣴⣤⣠⣀⢀")
M.spinner = to_astring("⠙⠸⢰⣠⣄⡤⢤⣠⣄⡆⠇⠋⠙⠚⠓⠋")
M.r_spinner = to_astring("⠋⠇⡆⣄⣠⢤⡤⣄⣠⢰⠸⠙⠋⠓⠚⠙")

--⠉⠉ ⠉⠋ ⠙⠝ ⠫⡫ ⢝⢝ ⡫⡫ ⢝⢝ ⡫⡫ ⢝⢝ ⡫⡩ ⢍⢉ ⡉⠉ ⠉⠉ ⠉⠉ ⠉⠉ ⠋⠉ ⠍⠉ ⡉⠉ ⠉⠉ ⠉⠉
M.rainer = to_double_wide_astring(
	"⠉⠉⠙⠫⢝⡫⢝⡫⢍⡉⠉⠉⠉⠉⠉",
	"⠉⠋⠝⡫⢝⡫⢝⡩⢉⠉⠉⠋⠍⡉⠉"
)
M.sworl = to_double_wide_astring(
	"⠙⠸⢰⣠⣄⡤⢤⣠⣄⡆⠇⠋⠙⠚⠓⠋",
	"⠋⠇⡆⣄⣠⢤⡤⣄⣠⢰⠸⠙⠋⠓⠚⠙"
)
M.blackbird_icon = "\xf0\x9f\x90\xa6\xe2\x80\x8d\xe2\xac\x9b"

local function debug_banner()
	return function(at_frame)
		local animations =
			{ to_astring(""), M.looper, M.sandpile, M.faller, M.spinner, M.r_spinner, M.rainer, to_astring("") }
		local msg = "DEBUG| "
		for cheater, anim in ipairs(animations) do
			local char = anim(at_frame)
			if not char then
				logger():log("ERROR", "Error at " .. cheater)
				char = ""
			end
			msg = msg .. char .. "| "
		end
		return msg .. "DEBUG"
	end
end

---@param message string
---@param outer_animation MnAString
---@param outer_timefactor number
---@param inner_animation MnAString
---@param inner_timefactor number
function M.new_dual_animation_banner(message, outer_animation, outer_timefactor, inner_animation, inner_timefactor)
	---@param at_frame number
	return function(at_frame)
		local o = outer_animation(math.floor(at_frame / outer_timefactor))
		local i = inner_animation(math.floor(at_frame / inner_timefactor))

		return o
			.. " "
			.. M.blackbird_icon
			.. " "
			.. i
			.. " "
			.. message
			.. " "
			.. i
			.. " "
			.. M.blackbird_icon
			.. " "
			.. o
	end
end

---@class MnAnimation
---@field t_start MnTime
---@field target_fps number
---@field frame_number number
---@field banner MnBanner
---@field fg_start MnColor
---@field fg_end MnColor?
---@field fg_gradient MnColorGradientFn
---@field bg_start MnColor
---@field bg_end MnColor?
---@field bg_gradient MnColorGradientFn
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

---@return string message
function MnAnimation:message()
	return self.banner(self.frame_number)
end

---@param t MnTime
function MnAnimation:set_duration(t)
	self.duration = t
	self.oscillator = time.new_oscillator(t)
end

---@return table {fg, bg}
function MnAnimation:get_hl()
	local fg, bg
	local t = time.new_time()
	local t_diff = t:diff(self.t_start)
	if self.fg_start and self.fg_end then
		fg = self.fg_gradient(self.fg_start, self.fg_end, self.oscillator:at(t_diff))
	elseif self.fg_start then
		fg = self.fg_start
	else
		fg = color.black
	end
	if self.bg_start and self.bg_end then
		bg = self.bg_gradient(self.bg_start, self.bg_end, self.oscillator:at(t_diff))
	elseif self.bg_start then
		bg = self.bg_start
	else
		bg = color.white
	end
	return { fg = tostring(fg), bg = tostring(bg) }
end

---Creates a new animation instance with the specified parameters
---@param banner MnBanner The text to display in the center of the animation
---@param fg_start MnColor Starting foreground color
---@param bg_start MnColor Starting background color
---@param duration MnTime Duration of the animation cycle
---@return MnAnimation
local function new_animation(banner, fg_start, bg_start, duration)
	return setmetatable({
		t_start = time.new_time(),
		banner = banner,
		fg_start = fg_start,
		fg_gradient = color.gradient_linear,
		bg_start = bg_start,
		bg_gradient = color.gradient_linear,
		target_fps = 24,
		frame_number = 0,
		duration = duration,
		oscillator = time.new_oscillator(duration),
	}, MnAnimation)
end

---@return MnAnimation
function M.new_autocomplete_animation()
	local banner = M.new_dual_animation_banner(" Muninn Autocompleting ", M.rainer, 6, M.sandpile, 8)
	local anim = new_animation(banner, color.muninn_orange, color.muninn_background, time.new_time(10))
	anim.fg_gradient = color.gradient_triangular(color.muninn_orange)
	anim.fg_end = color.muninn_orange_saturated

	anim.bg_gradient = color.gradient_triangular(color.muninn_blue)
	anim.bg_end = color.muninn_background
	anim.target_fps = 48

	return anim
end

---@return MnAnimation
function M.new_query_animation()
	local banner = M.new_dual_animation_banner(" Muninn Working ", M.sworl, 4, M.crawler, 2)
	local anim = new_animation(banner, color.muninn_orange, color.muninn_background, time.new_time(6))

	anim.fg_gradient = color.gradient_triangular(color.muninn_orange_saturated)
	anim.fg_end = color.muninn_orange

	anim.bg_gradient = color.gradient_triangular(color.muninn_blue)
	anim.bg_end = color.muninn_background
	anim.target_fps = 48

	return anim
end

function M.new_demo_animation()
	local banner = debug_banner()
	local anim = new_animation(banner, color.muninn_blue, color.black, time.new_time(1))
	anim.fg_end = color.white
	return anim
end

function M.new_failure_animation()
	local banner = M.new_dual_animation_banner(" Muninn Failed — :MuninnLog for details ", M.faller, 1, M.looper, 1)
	local anim = new_animation(banner, color.red, color.black, time.new_time(1))
	anim.fg_gradient = color.gradient_triangular(color.white)
	anim.fg_end = color.red

	anim.bg_gradient = color.gradient_triangular(color.new_color_from_hex("#404040"))
	anim.bg_end = color.black
	return anim
end

return M
