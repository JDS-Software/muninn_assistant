-- time_test.lua
-- Tests for lua/muninn/util/time.lua

local M = {}
local time = require("muninn.util.time")

local function near(a, b) return math.abs(a - b) < 1e-9 end

local function test_new_time_with_args()
	local t = time.new_time(5, 500000000)
	assert_equal(5, t.sec)
	assert_equal(500000000, t.nsec)
end

local function test_new_time_sec_only()
	local t = time.new_time(3)
	assert_equal(3, t.sec)
	assert_equal(0, t.nsec)
end

local function test_new_time_nsec_only()
	local t = time.new_time(nil, 750000000)
	assert_equal(0, t.sec)
	assert_equal(750000000, t.nsec)
end

local function test_new_time_no_args()
	local t = time.new_time()
	assert_true(t.sec >= 0)
	assert_not_nil(t.nsec)
end

local function test_diff()
	local d = time.new_time(10, 500000000):diff(time.new_time(3, 200000000))
	assert_equal(7, d.sec)
	assert_equal(300000000, d.nsec)
end

local function test_diff_negative_nsec()
	local d = time.new_time(5, 100000000):diff(time.new_time(3, 400000000))
	assert_equal(2, d.sec)
	assert_equal(-300000000, d.nsec)
end

local function test_diff_is_mntime()
	assert_equal(6000, time.new_time(10, 0):diff(time.new_time(4, 0)):to_millis())
end

local function test_to_millis()
	assert_equal(0, time.new_time(0, 0):to_millis())
	assert_equal(3000, time.new_time(3, 0):to_millis())
	assert_equal(500, time.new_time(0, 500000000):to_millis())
	assert_equal(2750, time.new_time(2, 750000000):to_millis())
end

local function test_to_millis_truncates()
	assert_equal(1, time.new_time(0, 1999999):to_millis())
end

local function test_oscillator_key_points()
	local osc = time.new_oscillator(time.new_time(4, 0))
	assert_true(near(1.0, osc:at(time.new_time(0, 0))))   -- t=0: peak
	assert_true(near(0.5, osc:at(time.new_time(1, 0))))   -- t=1/4: midpoint
	assert_true(near(0.0, osc:at(time.new_time(2, 0))))   -- t=1/2: trough
	assert_true(near(0.5, osc:at(time.new_time(3, 0))))   -- t=3/4: midpoint
end

local function test_oscillator_wraps()
	local osc = time.new_oscillator(time.new_time(2, 0))
	assert_true(near(1.0, osc:at(time.new_time(2, 0))))
	assert_true(near(1.0, osc:at(time.new_time(4, 0))))
end

local function test_oscillator_range()
	local osc = time.new_oscillator(time.new_time(1, 0))
	for ms = 0, 999, 50 do
		local val = osc:at(time.new_time(0, ms * 1000000))
		assert_true(val >= -1e-9 and val <= 1.0 + 1e-9)
	end
end

function M.run()
	local runner = TestRunner.new("time")
	runner:test("new_time with both args", test_new_time_with_args)
	runner:test("new_time sec only defaults nsec to 0", test_new_time_sec_only)
	runner:test("new_time nsec only defaults sec to 0", test_new_time_nsec_only)
	runner:test("new_time no args uses monotonic clock", test_new_time_no_args)
	runner:test("diff", test_diff)
	runner:test("diff with negative nsec", test_diff_negative_nsec)
	runner:test("diff returns MnTime", test_diff_is_mntime)
	runner:test("to_millis", test_to_millis)
	runner:test("to_millis truncates sub-ms", test_to_millis_truncates)
	runner:test("oscillator key points", test_oscillator_key_points)
	runner:test("oscillator wraps at period boundary", test_oscillator_wraps)
	runner:test("oscillator always in [0,1]", test_oscillator_range)
	runner:run()
end

return M
