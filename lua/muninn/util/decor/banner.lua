local M = {}
local logger = require("muninn.util.log").default

---@alias MnBanner fun(at_frame: number): string
---@alias MnAString fun(idx:number): string
function M.to_astring(str)
    local backing = vim.fn.split(str, "\\zs")
    return function(idx)
        return backing[(idx % #backing) + 1] or ""
    end
end

function M.to_double_wide_astring(stra, strb)
    local backinga = vim.fn.split(stra, "\\zs")
    local backingb = vim.fn.split(strb, "\\zs")
    return function(idx)
        local a = backinga[(idx % #backinga) + 1] or ""
        local b = backingb[(idx % #backingb) + 1] or ""
        return a .. b
    end
end

local looper_str = "⠛⠹⢸⣰⣤⣆⡇⠏"
local sandpile_str = "⢀⣀⣠⣤⣴⣶⣾⣿⣶⣤⣀⢀  "
local crawler_str = "⢀⣀⣠⣤⣴⣶⣾⣿⡿⠿⠟⠛⠋⠉⠁"
local faller_str = "⠁⠉⠋⠛⠟⠿⡿⣿⣾⣶⣴⣤⣠⣀⢀"
local spinner_str = "⠙⠸⢰⣠⣄⡤⢤⣠⣄⡆⠇⠋⠙⠚⠓⠋"
local r_spinner_str = "⠋⠇⡆⣄⣠⢤⡤⣄⣠⢰⠸⠙⠋⠓⠚⠙"

local rainer_left_str = "⠉⠉⠙⠫⢝⡫⢝⡫⢍⡉⠋⠍⡉⠉⠉"
local rainer_right_str = "⠉⠋⠝⡫⢝⡫⢝⡩⢉⠉⠉⠋⠍⡉⠉"

M.looper = M.to_astring(looper_str)
M.sandpile = M.to_astring(sandpile_str)
M.crawler = M.to_astring(crawler_str)
M.faller = M.to_astring(faller_str)
M.spinner = M.to_astring(spinner_str)
M.r_spinner = M.to_astring(r_spinner_str)

--⠉⠉ ⠉⠋ ⠙⠝ ⠫⡫ ⢝⢝ ⡫⡫ ⢝⢝ ⡫⡫ ⢝⢝ ⡫⡩ ⢍⢉ ⡉⠉ ⠉⠉ ⠉⠉ ⠉⠉ ⠋⠉ ⠍⠉ ⡉⠉ ⠉⠉ ⠉⠉
M.rainer = M.to_double_wide_astring(rainer_left_str, rainer_right_str)
M.sworl = M.to_double_wide_astring(r_spinner_str, spinner_str)
M.blackbird_icon = "\xf0\x9f\x90\xa6\xe2\x80\x8d\xe2\xac\x9b"

function M.debug_banner()
    return function(at_frame)
        local animations =
        { M.to_astring(""), M.looper, M.sandpile, M.faller, M.spinner, M.r_spinner, M.rainer, M.to_astring("") }
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
---@return MnBanner
function M.new_mono_animation_banner(message, outer_animation, outer_timefactor)
    ---@param at_frame number
    return function(at_frame)
        local o = outer_animation(math.floor(at_frame / outer_timefactor))

        return o .. " " .. M.blackbird_icon .. " " .. message .. " " .. M.blackbird_icon .. " " .. o
    end
end

return M
