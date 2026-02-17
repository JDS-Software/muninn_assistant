local animation = require("muninn.util.decor.animation")
local context = require("muninn.util.context")
local banner = require("muninn.util.decor.banner")
local logger = require("muninn.util.log").default

---@param ctx MnContext
local function show_failure(ctx)
	ctx:reset_state()
	ctx:next_state()

	animation.new_failure_animation():start(ctx)

	vim.defer_fn(function()
		ctx:next_state()
	end, 5000)
end

local function show_query_annotation(ctx)
	ctx:reset_state()
	ctx:next_state()
	animation.new_query_animation():start(ctx)

	vim.defer_fn(function()
		ctx.an_context.preserve_ext = true
		ctx:next_state()
		vim.defer_fn(function()
			show_failure(ctx)
		end, 100)
	end, 5000)
end

local function do_debug_animation()
	local ctx = context.get_context_at_cursor()
	logger():log("INFO", "Test function")
	if ctx then
		local anim = animation.new_autocomplete_animation()
		ctx:next_state()

		anim:start(ctx)

		vim.defer_fn(function()
			ctx.an_context.preserve_ext = true
			ctx:next_state()
			vim.defer_fn(function()
				show_query_annotation(ctx)
			end, 100)
		end, 10000)
	end
end

local idx = 1

local function logbyte(byte)
	logger():log("INFO", idx .. " " .. char_at(mask_to_codepoint(byte)))
	idx = idx + 1
end

return function()
	logbyte(0b1)
	logbyte(0b10)
	logbyte(0b100)
	logbyte(0b1000)
	logbyte(0b10000)
	logbyte(0b100000)
	logbyte(0b1000000)
	logbyte(0b10000000)
	logger():log("INFO", "---")
	logbyte(0b1)
	logbyte(0b11)
	logbyte(0b111)
	logbyte(0b1111)
	logbyte(0b11111)
	logbyte(0b111111)
	logbyte(0b1111111)
	logbyte(0b11111111)
end
