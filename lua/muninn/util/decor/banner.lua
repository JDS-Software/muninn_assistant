local M = {}
local logger = require("muninn.util.log").default
local pbm = require("muninn.util.img.pbm")

---@alias MnBanner fun(at_frame: number): table<string>

---@alias MnAString fun(idx:number): string

---@param str string
---@return MnAString
function M.to_astring(str)
    local backing = vim.fn.split(str, "\\zs")
    return function(idx)
        return backing[(idx % #backing) + 1] or ""
    end
end

---@param stra string
---@param strb string
---@return MnAString
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

local rainer_left_str = "⠉⠉⠙⠫⢝⣫⣝⣫⣝⣩⣉⣋⣍⣉⣉⢉⠉"
local rainer_right_str = "⠉⠋⠝⡫⣝⣫⣝⣫⣍⣉⣋⣍⣉⣉⣉⡉⠉"

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

---@param ctx MnContext
---@return MnBanner?
function M.debug_banner(ctx)
    local img_path = ctx:get_file("animations/debug.pbm")
    logger():log("INFO", "img_path: " .. img_path)
    local img = pbm.read(img_path)
    if img then
        local banner = M.new_spritemap_banner("Spritemap Banner", img, 4)
        return banner
    end
end

---@param message string
---@param animation MnAString
---@param timefactor number
---@return MnBanner
function M.new_mono_animation_banner(message, animation, timefactor)
    ---@param at_frame number
    return function(at_frame)
        local o = animation(math.floor(at_frame / timefactor))

        return { o .. " " .. M.blackbird_icon .. " " .. message .. " " .. M.blackbird_icon .. " " .. o }
    end
end

---@param message string appended to bottom of image
---@param images table<table<string>> flipbook of "images"
---@param timefactor number
---@return MnBanner
function M.new_flipbook_banner(message, images, timefactor)
    ---@param at_frame number
    ---@return table<string>
    return function(at_frame)
        local idx = (math.floor(at_frame / timefactor) % #images) + 1
        local stack = vim.deepcopy(images[idx])
        stack[#stack] = stack[#stack] .. message .. " " .. M.blackbird_icon
        return stack
    end
end

---@param message string appended to bottom of image
---@param image MnFrame frame atlas which can be subdivided into an animation. The image will be divided into equal parts based on the width
---@param timefactor number
---@return MnBanner
function M.new_spritemap_banner(message, image, timefactor)
    local lines = image:to_lines()
    local parts = image.height / image.width
    local rows_per_part = (#lines / parts) - 1
    if rows_per_part - math.floor(rows_per_part) > 0 then
        error("Image's height must be an exact multiple of its width", 2)
    end
    local frames = {}
    for i = 0, parts - 1 do
        local start_row = (i + 1) + (i * rows_per_part)
        local end_row = (start_row + rows_per_part)
        local frame = {}
        for j = start_row, end_row do
            local line = lines[j]
            if j == end_row then
                line = line .. message .. " " .. M.blackbird_icon
            end
            table.insert(frame, line)
        end

        table.insert(frames, frame)
    end

    ---@param at_frame number
    ---@return table<string>
    return function(at_frame)
        local idx = (math.floor(at_frame / timefactor) % #frames) + 1
        return frames[idx]
    end
end

return M
