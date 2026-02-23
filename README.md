# Muninn

> **This project is a work in progress.** Expect rough edges, breaking changes, and incomplete features.

> **Security notice:** Muninn invokes the [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) as a subprocess. Your buffer contents are sent to the Claude API over the network. Do not use Muninn on files containing secrets, credentials, or sensitive data you would not send to a third-party API.

AI-powered code editing inside Neovim. Place your cursor on a function, run a command, and Claude rewrites it in-place. Animated visual feedback keeps you informed while it works.

## Features

- **Autocomplete** — Complete the function at your cursor automatically.
- **Prompted edits** — Describe what you want changed in a floating prompt, and Claude rewrites the function.
- **Q&A** — Ask a question about your code and get an answer in a floating window, without modifying the buffer.
- **Scope highlighting** — The current function scope is highlighted as you navigate.

## Requirements

- Neovim 0.10+ with tree-sitter support
- Tree-sitter parsers for your languages
- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) installed and on your `$PATH`

## Installation

### lazy.nvim

```lua
{
    "JDS-Software/muninn",
    opts = {},
}
```

### packer.nvim

```lua
use {
    "JDS-Software/muninn",
    config = function()
        require("muninn").setup()
    end,
}
```

### vim-plug

```vim
Plug 'JDS-Software/muninn'
```

## Commands and Keymaps

| Command | Keymap | Description |
|---|---|---|
| `:MuninnAutocomplete` | `<leader>ma` | Auto-complete the function at the cursor |
| `:MuninnPrompt` | `<leader>mp` | Describe edits in a prompt, then rewrite the function |
| `:MuninnQuestion` | `<leader>mq` | Ask a question about your code |
| `:MuninnLog` | `<leader>ml` | Show the session log |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE)
