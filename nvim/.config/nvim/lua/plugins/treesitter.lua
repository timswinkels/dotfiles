return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      local config = require("nvim-treesitter.configs")
      config.setup({
        auto_install = false,
        ensure_installed = {
          "bash",
          "css",
          "dockerfile",
          "editorconfig",
          "git_rebase",
          "gitcommit",
          -- "gitconfig",
          "gitignore",
          "html",
          "javascript",
          "jsdoc",
          "json",
          -- "jsx",
          "lua",
          "markdown",
          "regex",
          "scss",
          "sql",
          "toml",
          "typescript",
          "yaml",
        },
        highlight = { enable = true },
        indent = { enable = false },
      })
    end
  }
}
