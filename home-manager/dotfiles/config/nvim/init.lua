require("plugins")
require("editor")
require("cheat-sheet")

local g = vim.g

g.mapleader = ","

local nightfox = require("nightfox")
nightfox.setup({
  options = {
    transparent = true,
    styles = {
      comments = "italic",
      keywords = "bold",
      functions = "italic,bold"
    }
  }
})
vim.cmd("colorscheme hybridfox")

require("bindings")
