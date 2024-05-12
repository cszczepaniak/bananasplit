# bananasplit
A Neovim plugin to split things onto separate lines, driven by treesitter. Optional fallback to
[ArgWrap](https://git.foosoft.net/alex/vim-argwrap) for unsupported languages/TSNode types.

NOTE: this is in very early development and currently only Go is supported.

## Supported Languages and Nodes
- Go
  - Function Calls
  - Slice/array literals
  - Map literals
  - Struct literals
  - Function Declarations (input parameters and return parameters)

#### Wishlist
- Support for other languages

## Installation

### lazy.nvim

```lua
{
  'cszczepaniak/bananasplit',
  config = function()
    require('nvim-treesitter.configs').setup {
      bananasplit = {
        enable = true,
        keymaps = {
          split = '<leader>fl',
        },
        argwrap_fallback = true,
        auto_format = true,
      },
    }
  end,
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    -- Required if "argwrap_fallback" is true
    'FooSoft/vim-argwrap',
    -- Required if "auto_format" is true
    'stevearc/conform.nvim',
  }
}
```

## Why?
I haven't found a plugin yet that does exactly what I want. Consider the following Go example:

```go
func foo() {
  a.b.c("a", func(a, b string) {
    return 1
  }, "b")
}
```

The plugins I've tried try to _toggle_ the arguments being on one line or many lines. Some transform
this example into invalid Go code:

```go
func foo() {
  a.b.c("a", func(a, b string) {fmt.Println(a, b)return 1}, "b")
}
```

Some can't split the line at all for this example and only work if the arguments are already only on
one line.

Using treesitter should make this much safer because it's aware of the syntax tree.

Besides that, I just thought it'd be fun to learn how to use treesitter and how to write plugins.

## Similar Plugins
- [ArgWrap](https://git.foosoft.net/alex/vim-argwrap)
- [SplitJoin](https://github.com/AndrewRadev/splitjoin.vim)
