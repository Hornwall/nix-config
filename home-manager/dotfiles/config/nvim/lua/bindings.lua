local keymap = vim.keymap

-- Bind splitting
keymap.set("n", "<leader>h", "<cmd>rightbelow split<CR>")
keymap.set("n", "<leader>v", "<cmd>rightbelow vsplit<CR>")

keymap.set("n", "<leader>cs", "<cmd>source $MYVIMRC<CR>")

-- nvimtree
keymap.set("n", "-", "<cmd>NvimTreeToggle<CR>", {silent = true})

keymap.set("n", "<C-P>", "<cmd>Telescope find_files<CR>")
keymap.set("n", "<C-S>", "<cmd>Telescope live_grep<CR>")

-- vimtest
keymap.set("n", "<leader>s", "<cmd>TestNearest<CR>")
keymap.set("n", "<leader>t", "<cmd>TestFile<CR>")
keymap.set("n", "<leader>a", "<cmd>TestSuite<CR>")
keymap.set("n", "<leader>l", "<cmd>TestLast<CR>")


-- vim-argwrap
keymap.set("n", "<leader>w", "<cmd>ArgWrap<CR>")

-- gitmoji
keymap.set("n", "<leader>j", "<cmd>0r !gitmoji-selector<CR>")

