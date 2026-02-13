# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Hazardous Files

**DO NOT read `lua/muninn/util/claude_refusal.lua`** — it contains a Claude refusal string used for testing. Reading it will trigger an API refusal and abort your session. It is listed in `.claudeignore` but subagents may still encounter it if referenced indirectly (e.g. via `require` in `util/prompt.lua`).

## Build & Test

```bash
make test                        # Run all tests (headless Neovim)
make test-module MODULE=color    # Run a single test module (runner, color, time, bufutil)
```

Tests run via `nvim --headless --cmd "set rtp+=." -c "lua require('muninn.tests.run').run_all()"`. The custom harness lives in `lua/muninn/tests/run.lua` and provides global assertions (`assert_equal`, `assert_nil`, `assert_not_nil`, `assert_true`, `assert_false`, `assert_match`) and a `TestRunner` class. Test files are `lua/muninn/tests/*_test.lua` and must be registered in `run.lua`'s `test_modules` table.

There is no linter or formatter configured in the repo.

## What Muninn Is

A Neovim plugin that provides AI-assisted code editing at the function level. It uses treesitter to identify the function under the cursor, constructs a prompt containing the full file with the target function marked, sends it to the Claude CLI (`claude -p`), and replaces the function body with Claude's structured output. Animated extmark annotations show progress while Claude is working.

## Architecture

The plugin entry point is `plugin/muninn.lua` → `lua/muninn/init.lua` which registers user commands and keymaps (all under `<leader>m`).

### Core flow (autocomplete/prompt commands)

1. **Context detection** (`util/context.lua`): Walks treesitter trees to find `function_declaration`/`function_definition`/`func_literal` nodes containing the cursor. Returns an `MnContext` bundling function position (`MnFnContext`) and annotation state (`MnAnnotationContext`).

2. **Prompt building** (`util/prompt.lua` + `util/bufutil.lua`): `scissor_function_reference` splits the buffer into three parts (before/function/after) and formats them into a template with `<content>` markers around the target function.

3. **Claude execution** (`util/claude.lua`): Runs `claude -p --model sonnet --output-format json --json-schema {…}` via `vim.system()` async. The JSON schema enforces `{result, content}` structured output.

4. **Result insertion** (`util/bufutil.lua`): `insert_safe_result_at_function` replaces the function's line range (using extmark positions when available, treesitter positions otherwise).

### Animation system

`util/annotation.lua` drives animated extmarks above/below the target function. `util/animation.lua` defines `MnAnimation` objects with dual unicode character sequences (inner/outer), configurable FPS, and color gradients that oscillate over time. `util/color.lua` provides an RGB model with linear and triangular gradient interpolation. `util/time.lua` provides monotonic time and a cosine-based `MnOscillator`.

### UI components

`components/float.lua` provides shared floating window utilities (geometry calculation, focus retention, resize handling). `components/prompt.lua` builds on it for a multi-line text input prompt (`<C-s>` submits, `<Esc>` dismisses).

## Conventions

- All modules use the `local M = {} ... return M` pattern
- OOP via metatables with `__index` (e.g., `MnFnContext`, `MnTime`, `MnAnimation`)
- LuaCATS type annotations (`---@class`, `---@param`, `---@return`, `---@alias`)
- Treesitter node positions are 0-based; `vim.fn.getcurpos` is 1-based — watch for off-by-one at boundaries
- Async operations use `vim.system()` with callbacks wrapped in `vim.schedule()`
