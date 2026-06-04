-- nvim-treesitter (main-branch rewrite).
--
-- Parsers are provided precompiled via Nix
-- (programs.neovim -> pkgs.vimPlugins.nvim-treesitter.withAllGrammars), so they
-- are already on the runtimepath and we never need :TSInstall / :TSUpdate here.
--
-- The main branch dropped the old module system (`highlight`, `indent`,
-- `ensure_installed`, `define_modules`). Highlighting is now started per buffer
-- via `vim.treesitter.start()`, and indentation via `nvim-treesitter`'s
-- `indentexpr()`.

require("nvim-treesitter").setup {}

local group = vim.api.nvim_create_augroup("UserTreesitter", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  callback = function(args)
    -- Only enable for filetypes that actually have a parser available.
    -- pcall guards filetypes with no installed grammar.
    if not pcall(vim.treesitter.start, args.buf) then
      return
    end

    -- Treesitter-based indentation (experimental upstream, opt-in per buffer).
    vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})
