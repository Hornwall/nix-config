local packer = require("packer")
local use = packer.use

return packer.startup(function()
  use "wbthomason/packer.nvim"
  use "christoomey/vim-tmux-navigator"
--  use "EdenEast/nightfox.nvim"
  use { "micke/nightfox.nvim", branch = "hybridfox" }
  use "nvim-lua/plenary.nvim"
  use "nvim-telescope/telescope.nvim"

  use "tpope/vim-surround"
  use "tpope/vim-eunuch"
  use "tpope/vim-vinegar"
  use "tpope/vim-unimpaired"
  use "tpope/vim-fugitive"
  use "tpope/vim-rails"
  use "tpope/vim-dispatch"
  use "leafgarland/typescript-vim"
  use "FooSoft/vim-argwrap"
  use "sheerun/vim-polyglot"
  use "godlygeek/tabular"
  use "mg979/vim-visual-multi"
  use "AndrewRadev/deleft.vim"
  use "lervag/vimtex"

  use { 
    "vim-test/vim-test" ,
    config = function()
      require("plugins.configs.vim-test")
    end,
  }

  use {
    "laytan/tailwind-sorter.nvim",
    requires = {"nvim-treesitter/nvim-treesitter", "nvim-lua/plenary.nvim"},
    config = function() require("tailwind-sorter").setup({
      on_save_enabled = false,
      on_save_pattern = { "*.html", "*.erb", "*.js", "*.jsx", "*.tsx", "*.twig", "*.hbs", "*.php", "*.heex" }
    }) end,
    run = "cd formatter && npm ci && npm run build",
  }

  -- LSP
  use  {
    "neovim/nvim-lspconfig",
    config = function()
      require("plugins.configs.nvim-lsp")
    end,
  }
  use "onsails/lspkind-nvim"
  use "williamboman/nvim-lsp-installer"

  -- CMP
  use {
    "hrsh7th/nvim-cmp",
    config = function()
      require("plugins.configs.cmp")
    end,
  }
  use "hrsh7th/cmp-nvim-lsp"
  use "hrsh7th/cmp-buffer"
  use "hrsh7th/cmp-path"
  use "hrsh7th/cmp-vsnip"
  use {
    "kyazdani42/nvim-tree.lua",
    requires = {
      'kyazdani42/nvim-web-devicons', -- optional, for file icon
    },
    config = function()
      require("plugins.configs.nvimtree")
    end,
  }

  use "L3MON4D3/LuaSnip"
  use "saadparwaiz1/cmp_luasnip"

  use {
    "nvim-lualine/lualine.nvim",
    requires = {"kyazdani42/nvim-web-devicons", opt = true},
    config = function()
      require("plugins.configs.lualine")
    end,
  }

  -- Treesitter
 --use {
 --  "nvim-treesitter/nvim-treesitter",
 --  config = function()
 --    require "plugins.configs.treesitter"
 --  end,
 --  run = ":TSUpdate"
 --}
  use {
      "nvim-treesitter/nvim-treesitter-textobjects",
      after = "nvim-treesitter",
    }
  use {
    "folke/trouble.nvim",
    requires = "kyazdani42/nvim-web-devicons",
    config = function()
      require("trouble").setup {
        -- your configuration comes here
        -- or leave it empty to use the default settings
        -- refer to the configuration section below
      }
    end
  }

  use {
    "supermaven-inc/supermaven-nvim",
    after = "nvim-cmp",
    config = function()
      require("supermaven-nvim").setup({
        keymaps = {
          accept_suggestion = "<C-e>",
          clear_suggestion = "<C-]>",
          accept_word = "<C-j>",
        },
      })
    end,
  }

  use {
    "folke/snacks.nvim",
    config = function()
      -- Set keymaps for the dependency here
      vim.keymap.set("t", "<C-h>", "<cmd>TmuxNavigateLeft<cr>")
      vim.keymap.set("t", "<C-l>", "<cmd>TmuxNavigateRight<cr>")
    end
  }

  use {
    "coder/claudecode.nvim",
    requires = { "folke/snacks.nvim" },
    config = function()
      require("claudecode").setup()
      
      -- Key mappings
      local opts = { noremap = true, silent = true }
      
      -- AI/Claude Code group (description only)
      vim.keymap.set("n", "<leader>a", "<nop>", vim.tbl_extend("force", opts, { desc = "AI/Claude Code" }))
      
      -- Main commands
      vim.keymap.set("n", "<leader>ac", "<cmd>ClaudeCode<cr>", vim.tbl_extend("force", opts, { desc = "Toggle Claude" }))
      vim.keymap.set("n", "<leader>af", "<cmd>ClaudeCodeFocus<cr>", vim.tbl_extend("force", opts, { desc = "Focus Claude" }))
      vim.keymap.set("n", "<leader>ar", "<cmd>ClaudeCode --resume<cr>", vim.tbl_extend("force", opts, { desc = "Resume Claude" }))
      vim.keymap.set("n", "<leader>aC", "<cmd>ClaudeCode --continue<cr>", vim.tbl_extend("force", opts, { desc = "Continue Claude" }))
      vim.keymap.set("n", "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", vim.tbl_extend("force", opts, { desc = "Select Claude model" }))
      vim.keymap.set("n", "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", vim.tbl_extend("force", opts, { desc = "Add current buffer" }))
      
      -- Visual mode mapping
      vim.keymap.set("v", "<leader>as", "<cmd>ClaudeCodeSend<cr>", vim.tbl_extend("force", opts, { desc = "Send to Claude" }))
      
      -- File tree specific mapping
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "NvimTree", "neo-tree", "oil", "minifiles" },
        callback = function()
          vim.keymap.set("n", "<leader>as", "<cmd>ClaudeCodeTreeAdd<cr>", vim.tbl_extend("force", opts, { desc = "Add file", buffer = true }))
        end,
      })
      
      -- Diff management
      vim.keymap.set("n", "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", vim.tbl_extend("force", opts, { desc = "Accept diff" }))
      vim.keymap.set("n", "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", vim.tbl_extend("force", opts, { desc = "Deny diff" }))
    end,
  }
end)
