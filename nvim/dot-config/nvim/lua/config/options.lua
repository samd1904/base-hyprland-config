-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
-- Force Neo-tree to show hidden files by default
vim.g.root_spec = { "lsp", { ".git", "Makefile" }, "cwd" } -- standard root locating

-- Pass the configuration directly to Neo-tree via lazyvim options
vim.g.neotree_show_hidden = true
