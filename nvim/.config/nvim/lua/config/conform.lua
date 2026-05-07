local conform = require("conform")

conform.setup({
    timeout_ms = 10000,
    formatters = {
        eslint_vue = {
          command = "pnpm",
          args = { "eslint", "--fix", "$FILENAME" }, -- Use real file path!
          stdin = false, -- Must be false for SFCs
        },
    },
    formatters_by_ft = {
        -- Conform will run the first available formatter
        javascript = { "eslint", "eslint_lsp", "prettier", stop_after_first = true },
        typescript = { "eslint", "eslint_lsp", "prettier", stop_after_first = true },
        vue = { "eslint_vue", "prettier", stop_after_first = true },
    },
})

vim.keymap.set("n", "<leader>f", function() conform.format() end, { desc = "Run formatter with 'Conform'" })

