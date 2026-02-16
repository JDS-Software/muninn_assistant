# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Muninn is a Neovim plugin that provides AI-powered code completion and editing via the Claude API. It uses Treesitter to extract code context (functions, structs, variables) at the cursor, sends structured prompts to Claude, and replaces the target code region with the response. Animated visual feedback (pulsing Braille-character banners via extmark virtual lines) is displayed during operations.

## Commands

### Testing
```bash
make test                        # Run all tests
make test-module MODULE=runner   # Run a single test module (omit _test suffix)
```

Tests run in headless Neovim. The test harness is custom (`lua/muninn/tests/run.lua`) — tests use a `TestRunner` class and global assertion helpers (`assert_equal`, `assert_nil`, `assert_not_nil`, `assert_true`, `assert_false`, `assert_match`). New test modules must be added to the `test_modules` list in `run.lua`.

### Linting
The project uses `stylua` for Lua formatting.

## Dangerous Files

**DO NOT read `lua/muninn/util/claude_refusal.lua`.** It contains a Claude API test refusal string. Reading it will trigger refusal behavior and break your session. It is only referenced as a fallback return value in `util/prompt.lua` — you never need to open it.

## Architecture

### Core Flow

1. **Context extraction** (`util/context.lua`) — Treesitter walks the buffer AST to find all function/struct/variable declarations, wraps them as `MnFnContext` objects, and identifies which one contains the cursor.
2. **Prompt construction** (`util/prompt.lua`) — Splits the buffer into before/target/after sections using `bufutil.scissor_function_reference()`, then formats a template with `<content>` tags marking the replacement region.
3. **API call** (`util/claude.lua`) — Shells out to the `claude` CLI (`vim.system`) with `--output-format json` and `--json-schema` for structured output. The response is parsed as `ClaudeResult` with a `structured_output.content` field containing the replacement code.
4. **Result insertion** (`util/bufutil.lua`) — `insert_safe_result_at_function()` replaces the target region using extmark positions (handles line shifts).
5. **Visual feedback** (`util/decor/animation.lua`, `util/decor/banner.lua`) — Animated banners rendered at 24 FPS via `vim.defer_fn`, using extmark virtual lines at function boundaries.

### State Machine

Every operation uses `MnContext` (combines `MnFnContext` + `MnAnContext`) with states: **INIT → RUN → END**. The animation loop self-terminates when `ctx:finished()` returns true. On failure, the `preserve_ext` flag on `MnAnContext` keeps extmarks alive so the failure animation can reuse them — the context is reset to INIT, advanced to RUN, and a new failure animation plays on the same extmarks.

### Key Modules

- **`cmd/`** — Command handlers. `autocomplete.lua` (auto-completes the function at cursor) and `prompt.lua` (opens a dialog for user instructions) are the primary commands; `default.lua` and `test.lua` are demos. `log.lua` opens a floating window with the session log.
- **`util/context_util/`** — Data structures: `MnFnContext` (code location), `MnAnContext` (decoration state + extmarks), `MnLocation` (row/col range), `MnReference` (TSNode + location).
- **`util/color.lua`** — RGB colors with linear/triangular gradient interpolation and theme background detection.
- **`util/time.lua`** — `MnTime` (clock wrapper) and `MnOscillator` (cosine-based 0→1→0 cycling for animations).
- **`components/`** — Reusable UI: `float.lua` (floating window primitives) and `prompt.lua` (text input dialog).

### Plugin Entry Point

`plugin/muninn.lua` → `lua/muninn/init.lua` → registers commands (`Muninn`, `MuninnAutocomplete`, `MuninnPrompt`, `MuninnTest`, `MuninnLog`) and keymaps under `<leader>m` prefix.

## Conventions & Idioms

### Module Pattern

Every module uses `local M = {}` at the top and `return M` at the bottom. Exported functions are defined as `M.function_name()`. Local helpers use `local function helper_name()`. No exceptions.

Command modules in `cmd/` are the one variant — they return a bare function instead of a table, since they're registered directly as callbacks.

### Class Pattern

Classes use metatable-based OOP:

```lua
---@class MnThing
---@field name string
local MnThing = {}
MnThing.__index = MnThing

function MnThing:method()
    return self.name
end

-- Constructor is exported on M, the class table is NOT exported
function M.new(name)
    return setmetatable({ name = name }, MnThing)
end
```

Constructor naming: `M.new()` when a module exports one class, `M.new_thing()` when a module exports multiple (e.g., `M.new_time()` and `M.new_oscillator()` in `util/time.lua`). All classes use the `Mn` prefix: `MnTime`, `MnColor`, `MnFnContext`, `MnAnContext`, etc.

### Logging

The logger is a singleton accessed via a function:

```lua
local logger = require("muninn.util.log").default

-- Usage (note: logger is a function that returns the singleton)
logger():log("INFO", "message here")
logger():alert("ERROR", "shown to user via vim.notify AND logged")
logger():show(0.33, 0.80) -- open log in floating window
```

Log levels are freeform strings. `"INFO"` is the workhorse, `"ERROR"` for failures. Descriptive levels like `"AUTOCOMPLETE PROMPT"` are also used as informal categories.

### Error Handling

- **Nil returns** for expected failures — callers guard with `if ctx then ... end`
- **`pcall`** wraps Neovim API calls that might fail (e.g., `vim.treesitter.get_parser`, `nvim_open_win`)
- **`error()`** only for programmer errors / invalid input validation (not runtime failures)
- **Async errors**: callbacks receive `nil` on failure; callers check `if result and result.structured_output then`

### Type Annotations

EmmyLua / LuaLS-style annotations on all exported functions and class definitions:

```lua
---@alias MnState number
---@param bufnr number
---@return MnFnContext[]?
function M.get_contexts_for_buffer(bufnr) end

-- Inline casts:
M.STATE_INIT = 0 --[[@as MnState]]
local result = vim.json.decode(stdout) --[[@as ClaudeResult]]
```

Optional types use `?` suffix: `MnReference?`, `number?`. Complex params use inline table syntax: `---@param opts { width: number, height: number }`.

### Command Handler Shape

Standard command in `cmd/`:

```lua
local context = require("muninn.util.context")
local animation = require("muninn.util.decor.animation")
local claude = require("muninn.util.claude")
local logger = require("muninn.util.log").default

return function()
    local ctx = context.get_context_at_cursor()
    if ctx then
        -- 1. Build prompt
        -- 2. ctx:next_state() (INIT → RUN)
        -- 3. Start animation: animation.new_*_animation():start(ctx)
        -- 4. claude.execute_prompt(prompt, callback)
        -- 5. In callback: insert result or trigger failure, then ctx:next_state() (RUN → END)
    end
end
```

Failure recovery pattern (reuses extmarks for a failure animation):
```lua
ctx.an_context.preserve_ext = true
vim.defer_fn(function()
    ctx:reset_state()
    ctx:next_state()
    animation.new_failure_animation():start(ctx)
    vim.defer_fn(function() ctx:next_state() end, 5000)
end, 100)
```

### Async Patterns

- `vim.system()` for external process calls (Claude CLI), with a callback
- `vim.schedule()` wraps callback bodies to ensure Neovim API calls run on the main thread
- `vim.defer_fn(fn, ms)` for timed delays (animation frames, failure transitions)

### Test Structure

```lua
local M = {}

local function test_something()
    assert_equal(expected, actual, "description")
end

function M.run()
    local runner = TestRunner.new("module_name")
    runner:test("descriptive name", test_something)
    runner:run()
end

return M
```

`TestRunner` and all assertion helpers (`assert_equal`, `assert_nil`, `assert_not_nil`, `assert_true`, `assert_false`, `assert_match`) are globals injected by the harness. New test modules must be added to the `test_modules` list in `run.lua`.

### Naming

- **Classes**: `Mn` prefix, PascalCase (`MnFnContext`, `MnColor`)
- **Type aliases**: `Mn` prefix (`MnState`, `MnBanner`, `MnAString`)
- **Variables/functions**: `snake_case` throughout
- **Files**: lowercase with underscores (`fn_context.lua`, `event_listeners.lua`)
- **Test files**: `_test` suffix (`color_test.lua`, `time_test.lua`)
- **External API types**: use their own prefix (`ClaudeResult`, `ClaudeUsage`)
