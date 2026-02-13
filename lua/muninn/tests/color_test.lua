-- color_test.lua
-- Tests for lua/muninn/util/color.lua

local M = {}

local color = require("muninn.util.color")

local function assert_rgb(result, r, g, b)
    local eps = 1e-9
    assert_true(math.abs(result.r - r) < eps, string.format("r: expected %.4f got %.4f", r, result.r))
    assert_true(math.abs(result.g - g) < eps, string.format("g: expected %.4f got %.4f", g, result.g))
    assert_true(math.abs(result.b - b) < eps, string.format("b: expected %.4f got %.4f", b, result.b))
end

local function test_new_color()
    -- proportional
    assert_rgb(color.new_color(0.5, 0.25, 0.75), 0.5, 0.25, 0.75)

    --rgb
    assert_rgb(color.new_color_rgb(255, 0, 128), 1.0, 0.0, 128 / 255)
end

local function test_gradient_linear()
    --identity
    local same = color.new_color(0.3, 0.5, 0.7)
    assert_rgb(color.gradient_linear(same, same, 0.5), 0.3, 0.5, 0.7)

    -- endpoints
    local s = color.new_color(1, 0, 0)
    local e = color.new_color(0, 0, 1)
    assert_rgb(color.gradient_linear(s, e, 0), 1, 0, 0)
    assert_rgb(color.gradient_linear(s, e, 1), 0, 0, 1)

    -- interpolation
    local s = color.new_color(0, 0, 0)
    local e = color.new_color(1, 1, 1)
    assert_rgb(color.gradient_linear(s, e, 0.25), 0.25, 0.25, 0.25)
    assert_rgb(color.gradient_linear(s, e, 0.5), 0.5, 0.5, 0.5)

    --clamping
    local s = color.new_color(1, 0, 0)
    local e = color.new_color(0, 0, 1)
    assert_rgb(color.gradient_linear(s, e, -0.5), 1, 0, 0)
    assert_rgb(color.gradient_linear(s, e, 1.5), 0, 0, 1)
end

local function test_gradient_triangular()
    -- key points
    local mid = color.new_color(0, 1, 0)
    local grad = color.gradient_triangular(mid)
    local s = color.new_color(1, 0, 0)
    local e = color.new_color(0, 0, 1)
    assert_rgb(grad(s, e, 0), 1, 0, 0)        -- start
    assert_rgb(grad(s, e, 0.25), 0.5, 0.5, 0) -- halfway to mid
    assert_rgb(grad(s, e, 0.5), 0, 1, 0)      -- mid
    assert_rgb(grad(s, e, 0.75), 0, 0.5, 0.5) -- halfway from mid
    assert_rgb(grad(s, e, 1), 0, 0, 1)        -- end

    --clamping
    local grad = color.gradient_triangular(color.new_color(0, 1, 0))
    local s = color.new_color(1, 0, 0)
    local e = color.new_color(0, 0, 1)
    assert_rgb(grad(s, e, -1), 1, 0, 0)
    assert_rgb(grad(s, e, 2), 0, 0, 1)
end

local function test_color_strings()
    -- simple color matching
    assert_equal("#000000", tostring(color.new_color(0, 0, 0)))
    assert_equal("#ffffff", tostring(color.new_color(1, 1, 1)))

    -- round trip
    assert_equal(tostring(color.new_color_from_hex("#000000")), tostring(color.new_color(0, 0, 0)))
    assert_equal(tostring(color.new_color_from_hex("#808080")), tostring(color.new_color(0.5, 0.5, 0.5)))
    assert_equal(tostring(color.new_color_from_hex("#ffffff")), tostring(color.new_color(1, 1, 1)))
end

function M.run()
    local runner = TestRunner.new("color")

    runner:test("new_color stores r/g/b proportions", test_new_color)
    runner:test("linear gradient test", test_gradient_linear)
    runner:test("triangular gradient test", test_gradient_triangular)
    runner:test("to_string produces correct hex", test_color_strings)

    runner:run()
end

return M
