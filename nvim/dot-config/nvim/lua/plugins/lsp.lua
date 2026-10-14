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
      qmlls = {
        -- Additional settings needed so it attaches without a .git directory
        single_file_support = true,
        root_dir = function(bufnr_or_fname)
          local path = type(bufnr_or_fname) == "number" and vim.api.nvim_buf_get_name(bufnr_or_fname) or bufnr_or_fname
          if not path or path == "" then
            return nil
          end

          return vim.fs.root(path, { ".qmlls.ini", "CMakeLists.txt", "qmldir", ".git" }) or vim.fs.dirname(path)
        end,
      },
    },
  },
}
