-- bufutil_test.lua
-- Tests for lua/muninn/util/bufutil.lua

local M = {}

local bufutil = require("muninn.util.bufutil")

-- Helper: create a scratch buffer with given lines
local function make_buffer(lines)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    return buf
end

-- Helper: create a mock fn_context (0-based treesitter rows)
local function mock_fn_context(bufnr, start_row, start_col, end_row, end_col)
    local obj = { bufnr = bufnr }
    function obj:get_start()
        return start_row, start_col
    end

    function obj:get_end()
        return end_row, end_col
    end

    return obj
end

-- Helper: create a mock context without extmarks
local function mock_context(bufnr, start_row, start_col, end_row, end_col)
    return {
        fn_context = mock_fn_context(bufnr, start_row, start_col, end_row, end_col),
        an_context = {},
    }
end

-- Helper: create a mock context with real extmarks
local function mock_context_with_extmarks(bufnr, start_row, end_row)
    local ns = vim.api.nvim_create_namespace("bufutil_test_" .. tostring(vim.uv.hrtime()))
    local mark_start = vim.api.nvim_buf_set_extmark(bufnr, ns, start_row, 0, {})
    local mark_end = vim.api.nvim_buf_set_extmark(bufnr, ns, end_row, 0, {})
    return {
        fn_context = mock_fn_context(bufnr, start_row, 0, end_row, 0),
        an_context = {
            ext_namespace = ns,
            ext_mark_start = mark_start,
            ext_mark_end = mark_end,
        },
    }
end

-- Helper: assert table of strings matches
local function assert_lines(expected, actual, msg)
    assert_equal(#expected, #actual, (msg or "") .. " line count")
    for i, line in ipairs(expected) do
        assert_equal(line, actual[i], string.format("%s line %d", msg or "", i))
    end
end

-- Helper: read all lines from a buffer
local function read_buffer(bufnr)
    return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
end

-- scissor_function_reference

local function test_scissor()
    -- handles nil context
    local b, m, e = bufutil.scissor_function_reference()
    assert_nil(b)
    assert_nil(m)
    assert_nil(e)

    -- regular scissor function
    local buf = make_buffer({
        "before 1", -- i=1, row 0
        "before 2", -- i=2, row 1
        "fn start", -- i=3, row 2
        "fn body",  -- i=4, row 3
        "fn end",   -- i=5, row 4
        "after 1",  -- i=6, row 5
    })
    local ctx = mock_context(buf, 2, 0, 4, 0)
    local b, m, e = bufutil.scissor_function_reference(ctx)

    -- NOTE: ipairs is 1-based while treesitter rows are 0-based.
    -- begin:  i <= line_start(2)          → i=1,2
    -- middle: i > 2 and i <= end(4)+1=5   → i=3,4,5
    -- ending: else                        → i=6
    assert_lines({ "before 1", "before 2" }, b, "begin")
    assert_lines({ "fn start", "fn body", "fn end" }, m, "middle")
    assert_lines({ "after 1" }, e, "ending")

    --scissor at top
    buf = make_buffer({
        "fn line 1", -- i=1, row 0
        "fn line 2", -- i=2, row 1
        "after",     -- i=3, row 2
    })
    -- Function at rows 0..1
    ctx = mock_context(buf, 0, 0, 1, 0)
    b, m, e = bufutil.scissor_function_reference(ctx)

    -- begin:  i <= 0            → none
    -- middle: i > 0 and i <= 2  → i=1,2
    -- ending: else              → i=3
    assert_lines({}, b, "begin")
    assert_lines({ "fn line 1", "fn line 2" }, m, "middle")
    assert_lines({ "after" }, e, "ending")

    --scissor at bottom
    buf = make_buffer({
        "before",    -- i=1, row 0
        "fn line 1", -- i=2, row 1
        "fn line 2", -- i=3, row 2
    })
    -- Function at rows 1..2
    ctx = mock_context(buf, 1, 0, 2, 0)
    b, m, e = bufutil.scissor_function_reference(ctx)

    -- begin:  i <= 1            → i=1
    -- middle: i > 1 and i <= 3  → i=2,3
    -- ending: else              → (none)
    assert_lines({ "before" }, b, "begin")
    assert_lines({ "fn line 1", "fn line 2" }, m, "middle")
    assert_lines({}, e, "ending")

    -- scissor single line
    buf = make_buffer({
        "before",
        "local f = function() end",
        "after",
    })
    -- Single-line function at row 1, eRow = 1, so line_end = 2
    ctx = mock_context(buf, 1, 0, 1, 0)
    b, m, e = bufutil.scissor_function_reference(ctx)

    -- begin:  i <= 1            → i=1
    -- middle: i > 1 and i <= 2  → i=2
    -- ending: else              → i=3
    assert_lines({ "before" }, b, "begin")
    assert_lines({ "local f = function() end" }, m, "middle")
    assert_lines({ "after" }, e, "ending")
end

-- insert_safe_result_at_function

local function test_insert_safe_result_at_function()
    -- insert of equal size
    local buf = make_buffer({
        "line 0",
        "old function body",
        "line 2",
    })
    local ctx = mock_context(buf, 1, 0, 1, 0)
    bufutil.insert_safe_result_at_function(ctx, "new body")
    assert_lines({ "line 0", "new body", "line 2" }, read_buffer(buf), "single line replace")

    -- insert can increase line count
    buf = make_buffer({
        "line 0",
        "to replace",
        "line 2",
    })
    local ctx = mock_context(buf, 1, 0, 1, 0)
    bufutil.insert_safe_result_at_function(ctx, "a\nb\nc\nd")
    assert_lines({ "line 0", "a", "b", "c", "d", "line 2" }, read_buffer(buf), "expanded")

    -- insert can reduce line count
    buf = make_buffer({
        "line 0",
        "fn 1",
        "fn 2",
        "fn 3",
        "line 4",
    })
    local ctx = mock_context(buf, 1, 0, 3, 0)
    bufutil.insert_safe_result_at_function(ctx, "single")
    assert_lines({ "line 0", "single", "line 4" }, read_buffer(buf), "collapsed")
end

-- insert with extmarks

local function test_insert_uses_extmarks_when_present()
    local buf = make_buffer({
        "line 0",
        "line 1",
        "fn start",
        "fn end",
        "line 4",
    })
    -- Extmarks placed on rows 2 and 3
    local ctx = mock_context_with_extmarks(buf, 2, 3)
    bufutil.insert_safe_result_at_function(ctx, "replaced A\nreplaced B\nreplaced C")

    assert_lines(
        { "line 0", "line 1", "replaced A", "replaced B", "replaced C", "line 4" },
        read_buffer(buf),
        "extmark replace"
    )
end

local function test_insert_empty_result()
    local buf = make_buffer({
        "line 0",
        "fn body",
        "line 2",
    })
    local ctx = mock_context(buf, 1, 0, 1, 0)
    bufutil.insert_safe_result_at_function(ctx, "")

    assert_lines({ "line 0", "", "line 2" }, read_buffer(buf), "empty replacement")
end

-- runner

function M.run()
    local runner = TestRunner.new("bufutil")

    runner:test("scissor", test_scissor)
    runner:test("insert replaces range correctly", test_insert_safe_result_at_function)
    runner:test("insert extmarks when present", test_insert_uses_extmarks_when_present)
    runner:test("insert handles empty replacement string", test_insert_empty_result)

    runner:run()
end

return M
