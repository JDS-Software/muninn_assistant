local M = {}

local color = require("muninn.util.color")
local logger = require("muninn.util.log").default
local time = require("muninn.util.time")
local bann = require("muninn.util.decor.banner")
local pbm = require("muninn.util.img.pbm")

---@alias MnAnimationCallback fun()

---@class MnAnimation
---@field t_start MnTime
---@field target_fps number
---@field frame_number number
---@field banner MnBanner
---@field fg_gradient MnColorGradientFn
---@field bg_gradient MnColorGradientFn
---@field duration MnTime
---@field oscillator MnOscillator
---@field anim_cb MnAnimationCallback
---@field last_banner table<string> cached prior-frame banner message
local MnAnimation = {}
MnAnimation.__index = MnAnimation

---@param ctx MnContext
function MnAnimation:end_animation(ctx)
    ctx.an_context:reset(ctx.fn_context.bufnr)
end

---@param ctx MnContext
---@param message table<string>
function MnAnimation:get_virt_lines(ctx, message)
    local results = {}
    for _, line in ipairs(message) do
        table.insert(results, { { line, ctx.an_context.hl_group } })
    end
    return results
end

---@param ctx MnContext
---@param message table<string>
function MnAnimation:_update_banner(ctx, message)
    local virt_lines = self:get_virt_lines(ctx, message)
    local start_options = {
        id = ctx.an_context.ext_mark_start,
        virt_lines = virt_lines,
        virt_text_pos = "inline",
        virt_lines_above = true,
    }

    local sPos = vim.api.nvim_buf_get_extmark_by_id(
        ctx.fn_context.bufnr,
        ctx.an_context.ext_namespace,
        ctx.an_context.ext_mark_start,
        {}
    )

    vim.api.nvim_buf_set_extmark(
        ctx.fn_context.bufnr,
        ctx.an_context.ext_namespace,
        sPos[1],
        sPos[2],
        start_options
    )

    local end_options = {
        id = ctx.an_context.ext_mark_end,
        virt_lines = virt_lines,
        virt_text_pos = "eol",
    }
    local ePos = vim.api.nvim_buf_get_extmark_by_id(
        ctx.fn_context.bufnr,
        ctx.an_context.ext_namespace,
        ctx.an_context.ext_mark_end,
        {}
    )
    vim.api.nvim_buf_set_extmark(ctx.fn_context.bufnr, ctx.an_context.ext_namespace, ePos[1], ePos[2],
        end_options)
end

function MnAnimation:_create_anim_cb(ctx)
    return function()
        if ctx:finished() then
            logger():log("INFO", "animation over")
            self:end_animation(ctx)
            return
        end
        self:frame()

        vim.api.nvim_set_hl(0, ctx.an_context.hl_group, self:get_hl())

        local message = self:message()
        if not vim.deep_equal(message, self.last_banner) then
            self:_update_banner(ctx, message)
            self.last_banner = message
        end

        vim.defer_fn(self.anim_cb, self:get_wait())
    end
end

---@return number ms_to_wait
function MnAnimation:get_wait()
    return 1000 / self.target_fps
end

--- this will increment the internal frame state by 1
function MnAnimation:frame()
    self.frame_number = self.frame_number + 1
end

---@return table<string> message
function MnAnimation:message()
    return self.banner(self.frame_number)
end

---@param t MnTime
function MnAnimation:set_duration(t)
    self.duration = t
    self.oscillator = time.new_oscillator(t)
end

---returns the target time per frame
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

---@param ctx MnContext
function MnAnimation:start(ctx)
    logger():log("INFO", "annotation initialization")

    self.anim_cb = self:_create_anim_cb(ctx)
    logger():log("INFO", "launching animation")
    if self.anim_cb then
        ctx:next_state()
        self.anim_cb()
    end
end

--- Animation factories

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
        last_banner = {}
    }, MnAnimation)
end

---@return MnAnimation
function M.new_autocomplete_animation()
    local banner = bann.new_mono_animation_banner(" Muninn Autocompleting ", bann.rainer, 3)

    local background = color.get_theme_background()
    local bg_gradient = color.new_triangular_gradient(background, background:lerp(color.grey, 0.1), background)
    local anim = M.new_animation(banner, color.text_gradient, bg_gradient, time.new_time(4))


    return anim
end

---@return MnAnimation
function M.new_query_animation()
    local banner = bann.new_mono_animation_banner(" Muninn Working ", bann.sworl, 2)

    local background = color.get_theme_background()
    local bg_gradient = color.new_triangular_gradient(background, background:lerp(color.grey, 0.1), background)

    local anim = M.new_animation(banner, color.text_gradient, bg_gradient, time.new_time(6))

    return anim
end

---@param ctx MnContext
---@return MnAnimation
function M.new_question_animation(ctx)
    local img_filepath = ctx:get_file("animations/debug.pbm")
    local anim_frame = pbm.read(img_filepath)
    local msg = " Muninn Thinking"
    local banner = bann.new_mono_animation_banner(msg, bann.looper, 1)
    if anim_frame then
        banner = bann.new_spritemap_banner(msg, anim_frame, 1)
    end

    local fg_gradient = color.new_triangular_gradient(color.muninn_blue, color.muninn_blue:lerp(color.blue, 0.1),
        color.muninn_blue)

    local background = color.get_theme_background()
    local bg_gradient = color.new_triangular_gradient(background, background:lerp(color.white, 0.05), background)
    return M.new_animation(banner, fg_gradient, bg_gradient, time.new_time(3))
end

---@param ctx MnContext
function M.new_debug_animation(ctx)
    local banner = bann.debug_banner(ctx)
    local background = color.get_theme_background()
    local bg_gradient = color.new_triangular_gradient(background, background:lerp(color.grey, 0.1), background)
    local anim = M.new_animation(banner, color.text_gradient, bg_gradient, time.new_time(4))
    return anim
end

function M.new_failure_animation()
    local banner = bann.new_mono_animation_banner(" Muninn Failed — :MuninnLog for details ", bann.faller, 1)

    local bg_gradient = color.new_triangular_gradient(color.black, color.get_theme_background(), color.black)
    local anim = M.new_animation(banner, color.new_triangular_gradient(color.red, color.white, color.white), bg_gradient,
        time.new_time(1))

    return anim
end

return M
