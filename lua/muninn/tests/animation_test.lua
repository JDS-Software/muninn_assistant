-- animation_test.lua
-- Tests for lua/muninn/util/animation.lua

local M = {}

local animation = require("muninn.util.animation")
local color = require("muninn.util.color")
local time = require("muninn.util.time")

--- helper: create a minimal animation with predictable settings
local function make_test_animation()
    local banner = function(at_frame) return "frame:" .. at_frame end
    local fg = color.new_linear_gradient(color.black, color.white)
    local bg = color.white:to_grad()
    local dur = time.new_time(1)
    return animation.new_animation(banner, fg, bg, dur)
end

--- helper: create animation with a custom banner for frame inspection
local function make_counting_animation()
    local banner = function(at_frame) return tostring(at_frame) end
    local fg = color.new_linear_gradient(color.black, color.white)
    local bg = color.white:to_grad()
    local dur = time.new_time(1)

    -- Use demo animation as base, it's the simplest factory
    local anim = animation.new_animation(banner, fg, bg, dur)
    return anim
end

local function test_frame_starts_at_zero()
    local anim = make_counting_animation()
    assert_equal(0, anim.frame_number, "frame_number should start at 0")
    assert_equal("0", anim:message(), "message at frame 0 should reflect frame_number")
end

local function test_frame_increments()
    local anim = make_counting_animation()

    anim:frame()
    assert_equal(1, anim.frame_number, "frame_number should be 1 after one call")
    assert_equal("1", anim:message())

    anim:frame()
    assert_equal(2, anim.frame_number, "frame_number should be 2 after two calls")
    assert_equal("2", anim:message())
end

local function test_frame_increments_many()
    local anim = make_counting_animation()

    local n = 100
    for _ = 1, n do
        anim:frame()
    end

    assert_equal(n, anim.frame_number, "frame_number should match total calls")
    assert_equal(tostring(n), anim:message())
end

local function test_get_frame_time()
    local anim = make_test_animation() -- 24 fps, 1s duration

    -- frame 0 → 0ms
    assert_equal(0, anim:get_frame_time():to_millis(), "frame 0 should be 0ms")

    -- frame 24 → 1000ms (exactly 1 second at 24fps)
    anim.frame_number = 24
    assert_equal(1000, anim:get_frame_time():to_millis(), "frame 24 should be 1000ms")

    -- frame 12 → 500ms (half second)
    anim.frame_number = 12
    assert_equal(500, anim:get_frame_time():to_millis(), "frame 12 should be 500ms")

    -- frame 6 → 250ms
    anim.frame_number = 6
    assert_equal(250, anim:get_frame_time():to_millis(), "frame 6 should be 250ms")
end

local function test_gradient_follows_oscillator()
    -- black→white fg gradient, 1s duration, 24fps
    -- oscillator: (-cos(position * 2π) + 1) / 2
    --   position 0.0 → osc 0 → black
    --   position 0.5 → osc 1 → white
    --   position 1.0 → osc 0 → black (wraps)
    local anim = make_test_animation()

    -- frame 0: time=0ms, position=0, osc=0 → fg=black, bg=white
    local hl = anim:get_hl()
    assert_equal("#000000", hl.fg, "frame 0 fg should be black")
    assert_equal("#ffffff", hl.bg, "frame 0 bg should be constant white")

    -- frame 12: time=500ms, position=0.5, osc=1 → fg=white
    anim.frame_number = 12
    hl = anim:get_hl()
    assert_equal("#ffffff", hl.fg, "frame 12 fg should be white (oscillator peak)")
    assert_equal("#ffffff", hl.bg, "frame 12 bg should still be white")

    -- frame 24: time=1000ms, position=0 (wraps), osc=0 → fg=black
    anim.frame_number = 24
    hl = anim:get_hl()
    assert_equal("#000000", hl.fg, "frame 24 fg should be black (full cycle)")
end

function M.run()
    local runner = TestRunner.new("animation")

    runner:test("frame_number starts at zero", test_frame_starts_at_zero)
    runner:test("frame() increments frame_number by 1", test_frame_increments)
    runner:test("frame() increments correctly over many calls", test_frame_increments_many)
    runner:test("get_frame_time converts frames to milliseconds", test_get_frame_time)
    runner:test("gradient interpolation follows oscillator over frames", test_gradient_follows_oscillator)

    runner:run()
end

return M
