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

end)
