local opt = vim.opt

opt.backup      = false
opt.autoindent  = true
opt.writebackup = false
opt.swapfile    = false -- set history=50
opt.ruler       = true  -- show the cursor position all the time
opt.showcmd     = true  -- display incomplete commands
opt.incsearch   = true  -- do incremental searching
opt.autowrite   = true
opt.lazyredraw  = true

opt.clipboard = "unnamedplus"

-- Numbers
opt.relativenumber = true
opt.numberwidth    =5

opt.scrolloff = 3 -- Start scrollign when three lines from edge

-- Softtabs, 2 spaces
opt.tabstop    = 2
opt.shiftwidth = 2
opt.expandtab  = true

-- Display extra whitespace
opt.listchars = "tab:»·,trail:·"

-- Open new split panes to right and bottom, which feels more natural
opt.splitbelow = true
opt.splitright = true

-- Display current line in a different color
opt.cursorline = true
opt.colorcolumn = "80"

-- Do not wrap and color column 80
opt.wrap        = false

local vimrc_ex_group = vim.api.nvim_create_augroup("vimrcEx", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  pattern = "text",
  group = vimrc_ex_group,
  callback = function()
    vim.schedule(function()
      vim.bo.textwidth = 78
    end)
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  group = vimrc_ex_group,
  callback = function()
    vim.schedule(function()
      vim.wo.spell = true
    end)
  end,
})

