return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      sources = {
        files = {
          hidden = true, -- Show hidden dotfiles (.env)
          ignored = true, -- Show gitignored files (.env)
          exclude = {
            ".git",
            "node_modules", -- Keep node_modules completely invisible
            ".next",
          },
        },
        explorer = {
          hidden = true, -- Show hidden files (.env) by default
          ignored = true, -- Show gitignored files (node_modules, build/ dirs)
          exclude = {}, -- Empty this out so absolutely nothing is blocked
        },
      },
    },
  },
}
