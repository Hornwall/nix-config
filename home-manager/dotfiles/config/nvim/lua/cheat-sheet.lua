local function createWindow()
  -- We save handle to window from which we open the navigation
  start_win = vim.api.nvim_get_current_win()

  vim.api.nvim_command('botright vnew') -- We open a new vertical window at the far right
  win = vim.api.nvim_get_current_win() -- We save our navigation window handle...
  buf = vim.api.nvim_get_current_buf() -- ...and it's buffer handle.

  -- We should name our buffer. All buffers in vim must have unique names.
  -- The easiest solution will be adding buffer handle to it
  -- because it is already unique and it's just a number.
  vim.api.nvim_buf_set_name(buf, 'Oldfiles #' .. buf)

  -- Now we set some options for our buffer.
  -- nofile prevent mark buffer as modified so we never get warnings about not saved changes.
  -- Also some plugins treat nofile buffers different.
  -- For example coc.nvim don't triggers aoutcompletation for these.
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  -- We do not need swapfile for this buffer.
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  -- And we would rather prefer that this buffer will be destroyed when hide.
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  -- It's not necessary but it is good practice to set custom filetype.
  -- This allows users to create their own autocommand or colorschemes on filetype.
  -- and prevent collisions with other plugins.
  vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')

  -- For better UX we will turn off line wrap and turn on current line highlight.
  vim.api.nvim_win_set_option(win, 'wrap', false)
  vim.api.nvim_win_set_option(win, 'cursorline', true)

  --set_mappings() -- At end we will set mappings for our navigation.
end

local function redraw()
  -- First we allow introduce new changes to buffer. We will block that at end.
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)

  local items_count =  vim.api.nvim_win_get_height(win) - 1 -- get the window height
  local list = {
    "# Splits",
    "`<leader>h` - Horizontal split",
    "`<leader>v` - Vertical split",
    "",
    "# Config",
    "`<leader>cs` - Reload config",
    "",
    "# Nvimtree",
    "`-` - Open/Close nvimtree",
    "",
    "# Telescope",
    "`<C-P>` - Telescope find files",
    "`<C-S>` - Telescope find in files",
    "",
    "# vimtest",
    "`<C-P>` - Telescope find files",
    "`<leader>s` - Run closest test",
    "`<leader>t` - Run current test file",
    "`<leader>a` - Run full test suite",
    "`<leader>l` - Run last test",
    "",
    "# argwrap",
    "`<leader>w` - Wrap args",
    "",
    "# gitmoji",
    "`<leader>j` - Open gitmoji selector",
    "",
    "# nvimlsp",
    "`K` - Show docs for what is under cursor",
    "`gd` - Go to definition",
    "`gt` - Go to type definition",
    "`gt` - Go to implementation",
    "`<leader>r` - LSP rename",
    "`<leader>dj` - Go to next warning/error",
    "`<leader>dk` - Go to previous warning/error",
    "`<leader>dl` - Search warning/errors with Telescope",
    "`<leader>tr` - Search references for what is under cursor with Telescope",
    "",
    "# CMP",
    "`<Tab>` - Open completion / Switch to next completion",
    "`<S-Tab>` - Switch to previous completion",
    "",
    "# Treesitter - select",
    "## Visual mode",
    "`af` - Select outer function",
    "`if` - Select inner function",
    "`ac` - Select outer class",
    "`ic` - Select inner class",
    "`aa` - Select outer parameter",
    "`ia` - Select inner parameter",
    "`ab` - Select outer block",
    "`ib` - Select inner block",
    "",
    "# Treesitter - move",
    "`]m` - Go to start of next function",
    "`]]` - Go to start of next class",
    "`]M` - Go to next function end",
    "`][` - go to next class end",
    "`[m` - Go to previous function start",
    "`[[` - Go to previous class start",
    "`[M` - Go to end of previous function",
    "`[]` - go to end of previous class",
    "",
    "# Treesitter - move",
    "`<leader>a` - Swap parameter left to right",
    "`<leader>A` - Swap paramters right to left",
  }

  -- If you using nightly build you can get oldfiles like this
  local oldfiles = vim.v.oldfiles
  -- In stable version works only that
  local oldfiles = vim.api.nvim_get_vvar('oldfiles')
  -- We apply results to buffer
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, list)
  -- And turn off editing
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
end

local function cheatSheet()
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_set_current_win(win)
  else
    createWindow()
  end

  redraw()
end

local keymap = vim.keymap

keymap.set("n", "zz", cheatSheet)
