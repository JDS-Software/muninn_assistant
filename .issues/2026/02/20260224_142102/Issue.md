# 20260224_142102

## Version
1

## Status
OPEN

## Location
[location]
filepath = lua/muninn/tests/install_parsers.lua
reference[] = function_declaration|M.install

## Issue Description
Install currently does not work as expected.

The output from github actions is as follows:

```
Run git clone --depth 1 https://github.com/nvim-treesitter/nvim-treesitter.git /tmp/nvim-treesitter
Cloning into '/tmp/nvim-treesitter'...
[nvim-treesitter/install/go]: Downloading tree-sitter-go...
[nvim-treesitter/install/javascript]: Downloading tree-sitter-javascript...
[nvim-treesitter/install/python]: Downloading tree-sitter-python...
[nvim-treesitter/install/typescript]: Downloading tree-sitter-typescript...
[nvim-treesitter/install/ecma]: Language installed
[nvim-treesitter/install/jsx]: Language installed
[nvim-treesitter/install/python]: Compiling parser
[nvim-treesitter/install/go]: Compiling parser
[nvim-treesitter/install/javascript]: Compiling parser
go: MISSING
typescript: MISSING
python: MISSING
javascript: MISSING
[nvim-treesitter/install/typescript]: Compiling parser
Error: Process completed with exit code 1.
```

