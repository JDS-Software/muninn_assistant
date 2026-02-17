-- render_test.lua
-- Tests for lua/muninn/util/decor/render.lua

local M = {}

local render = require("muninn.util.decor.render")

local function to_binary(n)
	if type(n) ~= "number" then
		return vim.inspect(n)
	end
	if n == 0 then
		return "0b0"
	end
	local bits = {}
	local v = math.floor(n)
	while v > 0 do
		table.insert(bits, 1, v % 2)
		v = math.floor(v / 2)
	end
	return "0b" .. table.concat(bits)
end

local function assert_binary(expected, actual, message)
	if expected ~= actual then
		error(
			string.format(
				"%s\nExpected: %s\nActual:   %s",
				message or "Assertion failed",
				to_binary(expected),
				to_binary(actual)
			),
			2
		)
	end
end

local function test_new_frame()
	local bits = {}
	for i = 1, 16 do
		bits[i] = 0
	end

	-- minimum frame
	local frame = render.new_frame(bits, 4, 4)
	assert_not_nil(frame, "new_frame should return a frame")
	assert_equal(4, frame.width, "width should be 4")
	assert_equal(4, frame.height, "height should be 4")
	bits = {}
	for i = 1, 64 do
		bits[i] = i % 2
	end

	-- larger multiples are fine
	frame = render.new_frame(bits, 8, 8)
	assert_not_nil(frame, "new_frame should accept 8x8")
	assert_equal(8, frame.width)
	assert_equal(8, frame.height)

	-- error on bad width
	local ok, err = pcall(function()
		render.new_frame({}, 3, 4)
	end)
	assert_false(ok, "should reject width not multiple of 4")
	assert_match("width", err, "error should mention width")

	-- error on bad height
	ok, err = pcall(function()
		render.new_frame({}, 4, 5)
	end)
	assert_false(ok, "should reject height not multiple of 4")
	assert_match("height", err, "error should mention height")

	-- error on malformed bits
	bits = { 0, 0, 0, 0 }
	ok, err = pcall(function()
		render.new_frame(bits, 4, 4)
	end)
	assert_false(ok, "should reject when bits length != width * height")
	assert_match("bits length", err, "error should mention bits length")
end

local function test_frame_render()
    -- stylua: ignore
	local bits = {
		0, 0, 0, 0,
		0, 0, 0, 0,
		0, 0, 0, 0,
		0, 0, 0, 0,
	}

	local frame = render.new_frame(bits, 4, 4)
	local results = frame:_to_bytes()
	assert_binary(0, results[1], "blank frame left")
	assert_binary(0, results[2], "blank frame right")

    -- stylua: ignore
	bits = {
		1, 0, 0, 1,
		1, 0, 0, 1,
		1, 0, 0, 1,
		1, 0, 0, 1,
	}
	frame = render.new_frame(bits, 4, 4)
	results = frame:_to_bytes()
	assert_binary(0b1111, results[1], "first byte right col high")
	assert_binary(0b11110000, results[2], "second byte left col low")

    -- stylua: ignore
	bits = {
		0, 1, 1, 0,
		0, 1, 1, 0,
		0, 1, 1, 0,
		0, 1, 1, 0,
	}
	frame = render.new_frame(bits, 4, 4)
	results = frame:_to_bytes()
	assert_binary(0b11110000, results[1], "first byte right col high")
	assert_binary(0b1111, results[2], "second byte left col low")

    -- stylua: ignore
	bits = {
		1, 0, 1, 0,
		0, 1, 0, 1,
		1, 0, 0, 1,
		0, 1, 1, 0,
	}
	frame = render.new_frame(bits, 4, 4)
	results = frame:_to_bytes()
	assert_binary(0b01011010, results[1], "first byte pattern")
	assert_binary(0b01101001, results[2], "second byte pattern")
end

local function test_render_to_lines()
    -- stylua: ignore
	local bits = {
        0, 1, 1, 0,
		0, 1, 1, 0,
        0, 1, 1, 0,
		0, 1, 1, 0,
	}
	local frame = render.new_frame(bits, 4, 4)
	local results = frame:to_lines()
	assert_equal("⢸⡇", results[1], "line patterns")
end

function M.run()
	local runner = TestRunner.new("render")

	runner:test("new_frame creates valid frame", test_new_frame)
	runner:test("render test", test_frame_render)
	runner:test("render lines test", test_render_to_lines)

	runner:run()
end

return M
