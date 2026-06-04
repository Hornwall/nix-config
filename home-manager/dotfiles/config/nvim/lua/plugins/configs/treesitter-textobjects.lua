-- nvim-treesitter-textobjects (main-branch rewrite).
--
-- The main branch no longer registers keymaps through
-- `nvim-treesitter.configs`. Instead you call `setup` once and then bind keys
-- yourself to the `select` / `move` / `swap` module functions.

require("nvim-treesitter-textobjects").setup {
  select = {
    lookahead = true,
  },
  move = {
    set_jumps = true,
  },
}

local select = require("nvim-treesitter-textobjects.select")
local move = require("nvim-treesitter-textobjects.move")

-- Select textobjects (operator-pending + visual), mirroring the previous setup.
local selections = {
  ["af"] = "@function.outer",
  ["if"] = "@function.inner",
  ["ac"] = "@class.outer",
  ["ic"] = "@class.inner",
  ["aa"] = "@parameter.outer",
  ["ia"] = "@parameter.inner",
  ["ab"] = "@block.outer",
  ["ib"] = "@block.inner",
}
for lhs, obj in pairs(selections) do
  vim.keymap.set({ "x", "o" }, lhs, function()
    select.select_textobject(obj, "textobjects")
  end, { desc = "Select " .. obj })
end

-- Movement between functions/classes.
local moves = {
  goto_next_start = { ["]m"] = "@function.outer", ["]]"] = "@class.outer" },
  goto_next_end = { ["]M"] = "@function.outer", ["]["] = "@class.outer" },
  goto_previous_start = { ["[m"] = "@function.outer", ["[["] = "@class.outer" },
  goto_previous_end = { ["[M"] = "@function.outer", ["[]"] = "@class.outer" },
}
for fn, maps in pairs(moves) do
  for lhs, obj in pairs(maps) do
    vim.keymap.set({ "n", "x", "o" }, lhs, function()
      move[fn](obj, "textobjects")
    end, { desc = fn .. " " .. obj })
  end
end

-- NOTE: The previous config bound parameter swapping to <leader>a / <leader>A,
-- but <leader>a is now the opencode.nvim group prefix (see plugins.lua). Swap
-- keymaps are intentionally omitted to avoid clobbering it. To re-enable on
-- different keys:
--   local swap = require("nvim-treesitter-textobjects.swap")
--   vim.keymap.set("n", "<leader>sn", function() swap.swap_next("@parameter.inner") end)
--   vim.keymap.set("n", "<leader>sp", function() swap.swap_previous("@parameter.inner") end)
