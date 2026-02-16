-- color_test.lua
-- Tests for lua/muninn/util/color.lua

local M = {}

local color = require("muninn.util.color")

local function assert_rgb(result, r, g, b)
    local eps = 1e-9
    if math.abs(result.r - r) >= eps then
        error(string.format("r: expected %.4f got %.4f", r, result.r), 2)
    end
    if math.abs(result.g - g) >= eps then
        error(string.format("g: expected %.4f got %.4f", g, result.g), 2)
    end
    if math.abs(result.b - b) >= eps then
        error(string.format("b: expected %.4f got %.4f", b, result.b), 2)
    end
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
    local grad = color.new_linear_gradient(same, same)
    assert_rgb(grad(0.5), 0.3, 0.5, 0.7)

    -- endpoints
    local s = color.new_color(1, 0, 0)
    local e = color.new_color(0, 0, 1)
    grad = color.new_linear_gradient(s, e)
    assert_rgb(grad(0), 1, 0, 0)
    assert_rgb(grad(1), 0, 0, 1)

    -- interpolation
    s = color.new_color(0, 0, 0)
    e = color.new_color(1, 0, 0)
    grad = color.new_linear_gradient(s, e)
    for i = 1, 100, 1 do
        local x = i / 100
        local irp = grad(x)
        assert_rgb(irp, x, 0, 0)
    end

    --clamping
    s = color.new_color(1, 0, 0)
    e = color.new_color(0, 0, 1)
    grad = color.new_linear_gradient(s, e)
    assert_rgb(grad(-0.5), 1, 0, 0)
    assert_rgb(grad(1.5), 0, 0, 1)
end

local function test_gradient_triangular()
    -- key points
    local m = color.new_color(0, 1, 0)
    local s = color.new_color(1, 0, 0)
    local e = color.new_color(0, 0, 1)
    local grad = color.new_triangular_gradient(s, m, e)
    assert_rgb(grad(0), 1, 0, 0)        -- start
    assert_rgb(grad(0.25), 0.5, 0.5, 0) -- halfway to mid
    assert_rgb(grad(0.5), 0, 1, 0)      -- mid
    assert_rgb(grad(0.75), 0, 0.5, 0.5) -- halfway from mid
    assert_rgb(grad(1), 0, 0, 1)        -- end

    --clamping
    s = color.new_color(1, 0, 0)
    m = color.new_color(0, 1, 0)
    e = color.new_color(0, 0, 1)
    grad = color.new_triangular_gradient(s, m, e)
    assert_rgb(grad(-1), 1, 0, 0)
    assert_rgb(grad(2), 0, 0, 1)
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
