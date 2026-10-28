# Neovim

With [conform.nvim](https://github.com/stevearc/conform.nvim), in your `init.lua`:

```lua
require("conform").setup({
  formatters_by_ft = { dart = { "beaver" } },
  formatters = {
    beaver = {
      command = "beaver",
      args = { "--stdin", "--stdin-name", "$FILENAME" },
      range_args = function(_, ctx)
        local s, e = ctx.range.start, ctx.range["end"]
        return {
          "--stdin", "--stdin-name", ctx.filename,
          "--range", string.format("%d:%d-%d:%d", s[1], s[2] + 1, e[1], e[2] + 1),
        }
      end,
    },
  },
  format_on_save = { timeout_ms = 1000, lsp_format = "never" },
})
```

`:lua require("conform").format()` formats the buffer, and saving formats it too.

Selection formatting: available. In visual mode, `:lua require("conform").format()` formats the statements, members or declarations covering the selection (see [range formatting](../stdin-protocol.md)). Beaver counts columns in UTF-16 code units and conform reports bytes, so on lines with non-ASCII text the selection edge may land a little off; the range still expands to whole units.
