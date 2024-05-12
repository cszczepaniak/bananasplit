# bananasplit
A Neovim plugin to split things onto separate lines, driven by treesitter. Optional fallback to [ArgWrap]() for
unsupported languages/TSNode types.

## Supported Languages and Nodes
- Go
  - Function Calls

#### Wishlist
- Go
  - Function Declarations
  - Slice/array literals
  - Map literals
  - Struct literals
- Literally every other language that exists

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
      },
    }
  end,
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    -- Required if "argwrap_fallback" is true
    'FooSoft/vim-argwrap',
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

The plugins I've tried try to _toggle_ the arguments being on one line or many lines. They transform
this example into invalid Go code:

```go
func foo() {
  a.b.c("a", func(a, b string) {fmt.Println(a, b)return 1}, "b")
}
```

Using treesitter should make this much safer because it's aware of the syntax tree.

Besides that, I just thought it'd be fun to learn how to use treesitter and how to write plugins.

NOTE: this is in very early development and the number of languages/nodes supported is very small.
