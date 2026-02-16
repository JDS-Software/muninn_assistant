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
    "⠉⠉⠙⠫⢝⡫⢝⡫⢍⡉⠋⠍⡉⠉⠉",
    "⠉⠋⠝⡫⢝⡫⢝⡩⢉⠉⠉⠋⠍⡉⠉"
)
M.sworl = to_double_wide_astring(
    "⠋⠇⡆⣄⣠⢤⡤⣄⣠⢰⠸⠙⠋⠓⠚⠙",
    "⠙⠸⢰⣠⣄⡤⢤⣠⣄⡆⠇⠋⠙⠚⠓⠋"
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
function M.new_mono_animation_banner(message, outer_animation, outer_timefactor)
    ---@param at_frame number
    return function(at_frame)
        local o = outer_animation(math.floor(at_frame / outer_timefactor))

        return o .. " " .. M.blackbird_icon .. " " .. message .. " " .. M.blackbird_icon .. " " .. o
    end
end

---@class MnAnimation
---@field t_start MnTime
---@field target_fps number
---@field frame_number number
---@field banner MnBanner
---@field fg_gradient MnColorGradientFn
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

---@return MnTime computed run time
function MnAnimation:get_frame_time()
    local run_seconds = self.frame_number / self.target_fps
    return time.new_time(math.floor(run_seconds), math.floor((run_seconds % 1) * 1e9))
end

---@return table {fg, bg}
function MnAnimation:get_hl()
    local fg = self.fg_gradient(self.oscillator:at(self:get_frame_time()))
    local bg = self.bg_gradient(self.oscillator:at(self:get_frame_time()))

    return { fg = tostring(fg), bg = tostring(bg) }
end

---Creates a new animation instance with the specified parameters
---@param banner MnBanner The text to display in the center of the animation
---@param fg_gradient MnColorGradientFn Starting foreground color
---@param bg_gradient MnColorGradientFn Starting background color
---@param duration MnTime Duration of the animation cycle
---@return MnAnimation
function M.new_animation(banner, fg_gradient, bg_gradient, duration)
    return setmetatable({
        t_start = time.new_time(),
        banner = banner,
        fg_gradient = fg_gradient,
        bg_gradient = bg_gradient,
        target_fps = 24,
        frame_number = 0,
        duration = duration,
        oscillator = time.new_oscillator(duration),
    }, MnAnimation)
end

---@return MnAnimation
function M.new_autocomplete_animation()
    local banner = M.new_mono_animation_banner(" Muninn Autocompleting ", M.rainer, 3)

    local background = color.get_theme_background()
    local bg_gradient = color.new_triangular_gradient(background, background:lirp(color.grey, 0.1), background)
    local anim = M.new_animation(banner, color.text_gradient, bg_gradient, time.new_time(4))


    return anim
end

---@return MnAnimation
function M.new_query_animation()
    local banner = M.new_mono_animation_banner(" Muninn Working ", M.sworl, 2)


    local background = color.get_theme_background()
    local bg_gradient = color.new_triangular_gradient(background, background:lirp(color.grey, 0.1), background)

    local anim = M.new_animation(banner, color.text_gradient, bg_gradient, time.new_time(6))

    return anim
end

function M.new_demo_animation()
    local banner = debug_banner()
    local anim = M.new_animation(banner, color.new_linear_gradient(color.black, color.muninn_blue), color.white:to_grad(),
        time.new_time(1))
    return anim
end

function M.new_failure_animation()
    local banner = M.new_mono_animation_banner(" Muninn Failed — :MuninnLog for details ", M.faller, 1)

    local bg_gradient = color.new_triangular_gradient(color.black, color.get_theme_background(), color.black)
    local anim = M.new_animation(banner, color.new_triangular_gradient(color.red, color.white, color.white), bg_gradient,
        time.new_time(1))

    return anim
end

return M
