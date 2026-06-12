return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "oxfmt",
        "oxlint",
        "typescript-language-server",
        "prettier",
        "eslint-lsp",
      },
    },
  },
}
