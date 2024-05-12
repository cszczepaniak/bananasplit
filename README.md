# bananasplit
A Neovim plugin to split things onto separate lines. Optional fallback to [ArgWrap]() for
unsupported languages/TSNode types.

NOTE: this is in very early development and the number of languages/nodes supported is very small.

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
