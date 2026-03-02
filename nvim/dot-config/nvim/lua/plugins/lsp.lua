return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      jsonls = {
        -- This forces jsonls to stop formatting
        settings = {
          json = {
            format = {
              enable = false,
            },
          },
        },
      },
      vtsls = {
        settings = {
          typescript = {
            format = { enable = false },
          },
          javascript = {
            format = { enable = false },
          },
        },
      },
      ts_ls = {
        settings = {
          typescript = {
            format = { enable = false },
          },
          javascript = {
            format = { enable = false },
          },
        },
      },
    },
  },
}
