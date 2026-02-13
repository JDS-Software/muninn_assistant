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
	assert_rgb(color.new_color(0.5, 0.25, 0.75), 0.5, 0.25, 0.75)
end

local function test_new_color_rgb()
	assert_rgb(color.new_color_rgb(255, 0, 128), 1.0, 0.0, 128 / 255)
end

local function test_gradient_endpoints()
	local s = color.new_color(1, 0, 0)
	local e = color.new_color(0, 0, 1)
	assert_rgb(color.gradient(s, e, 0), 1, 0, 0)
	assert_rgb(color.gradient(s, e, 1), 0, 0, 1)
end

local function test_gradient_interpolation()
	local s = color.new_color(0, 0, 0)
	local e = color.new_color(1, 1, 1)
	assert_rgb(color.gradient(s, e, 0.25), 0.25, 0.25, 0.25)
	assert_rgb(color.gradient(s, e, 0.5), 0.5, 0.5, 0.5)
end

local function test_gradient_clamping()
	local s = color.new_color(1, 0, 0)
	local e = color.new_color(0, 0, 1)
	assert_rgb(color.gradient(s, e, -0.5), 1, 0, 0)
	assert_rgb(color.gradient(s, e, 1.5), 0, 0, 1)
end

local function test_gradient_identity()
	local same = color.new_color(0.3, 0.5, 0.7)
	assert_rgb(color.gradient(same, same, 0.5), 0.3, 0.5, 0.7)
end

local function test_to_string()
	assert_equal("#000000", tostring(color.new_color(0, 0, 0)))
	assert_equal("#ffffff", tostring(color.new_color(1, 1, 1)))
end

function M.run()
	local runner = TestRunner.new("color")

	runner:test("new_color stores r/g/b proportions", test_new_color)
	runner:test("new_color_rgb converts 0-255 to proportions", test_new_color_rgb)
	runner:test("gradient returns start/end at x=0/1", test_gradient_endpoints)
	runner:test("gradient interpolates correctly", test_gradient_interpolation)
	runner:test("gradient clamps x to [0,1]", test_gradient_clamping)
	runner:test("gradient with identical colors is identity", test_gradient_identity)
	runner:test("to_string produces correct hex", test_to_string)

	runner:run()
end

return M
