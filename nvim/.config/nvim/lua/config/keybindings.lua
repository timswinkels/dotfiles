vim.g.mapleader = " "

-- Open netrw
vim.keymap.set("n", "<leader>e", vim.cmd.Ex)

-- Yank till end of line
vim.keymap.set("n", "Y", "yg$")

-- Keeping it centered
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- Undo break points
vim.keymap.set("i", ".", ".<c-g>u")
vim.keymap.set("i", ";", ";<c-g>u")
vim.keymap.set("i", "=", "=<c-g>u")
vim.keymap.set("i", "{", "{<c-g>u")
vim.keymap.set("i", "{", "{<c-g>u")
vim.keymap.set("i", "(", "(<c-g>u")
vim.keymap.set("i", ")", ")<c-g>u")

-- Move text around
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Paste without overwriting default registry
-- vim.keymap.set("v", "<leader>p", [["_dP]])

-- Yank into system's clipboard
-- vim.keymap.set({"n", "v"}, "<leader>y", [["+y]])

-- Split window
vim.keymap.set("n", "<leader>v", "<Cmd>vsplit<CR>", { desc = "Split window vertically" })

-- Replace word your on
-- vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

vim.keymap.set("n", "<leader>gg", "<Cmd>GitGutterLineHighlightsToggle<CR>", { desc = "Toggle GitGutter line highlights" })

