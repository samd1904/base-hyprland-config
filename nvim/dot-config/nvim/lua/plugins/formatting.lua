return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      typescript = { "prettier" },
      javascript = { "prettier" },
    },
    -- This ensures LazyVim doesn't try to use the LSP if prettier fails
    format_on_save = {
      lsp_fallback = false,
      timeout_ms = 500,
    },
  },
}
