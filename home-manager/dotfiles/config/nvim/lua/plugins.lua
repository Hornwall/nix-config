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
    "nickjvandyke/opencode.nvim",
    requires = {
      {
        "folke/snacks.nvim",
        config = function()
          local ok, snacks = pcall(require, "snacks")
          if ok and type(snacks.setup) == "function" then
            -- Enable only what opencode.nvim uses.
            snacks.setup({ input = {}, picker = {}, terminal = {} })
          end
        end,
      },
    },
    config = function()
      -- Required for opencode.nvim's buffer reload integration.
      vim.o.autoread = true

      -- Auto-reload files changed outside Neovim (e.g. by opencode).
      local reload_group = vim.api.nvim_create_augroup("AutoReloadExternalChanges", { clear = true })

      vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI", "TermClose" }, {
        group = reload_group,
        callback = function()
          if vim.fn.mode() ~= "c" then
            vim.cmd("checktime")
          end
        end,
      })

      vim.api.nvim_create_autocmd("FileChangedShellPost", {
        group = reload_group,
        callback = function()
          vim.notify("File reloaded from disk", vim.log.levels.INFO)
        end,
      })

      -- opencode.nvim reads configuration from this global.
      vim.g.opencode_opts = vim.tbl_deep_extend("force", vim.g.opencode_opts or {}, {
        provider = {
          enabled = "snacks",
          snacks = {
            auto_close = true,
            win = {
              position = "right",
              enter = false, -- Keep focus in the editor by default
              wo = { winbar = "" },
              bo = { filetype = "opencode_terminal" },
            },
          },
        },
      })

      local opts = { noremap = true, silent = true }

      local opencodeGroup = vim.api.nvim_create_augroup("OpencodeCustomKeys", { clear = true })

      -- When any terminal opens, keep tmux navigation working.
      vim.api.nvim_create_autocmd("TermOpen", {
        group = opencodeGroup,
        callback = function()
          local term_opts = { buffer = true, noremap = true, silent = true }
          vim.keymap.set("t", "<C-h>", "<cmd>TmuxNavigateLeft<cr>", term_opts)
          vim.keymap.set("t", "<C-l>", "<cmd>TmuxNavigateRight<cr>", term_opts)
        end,
      })

      local function focus_opencode_terminal()
        require("opencode").start()

        for _, win in ipairs(vim.api.nvim_list_wins()) do
          local buf = vim.api.nvim_win_get_buf(win)
          local ft = vim.bo[buf].filetype
          if ft == "opencode_terminal" or ft == "opencode" then
            vim.api.nvim_set_current_win(win)
            vim.cmd("startinsert")
            return
          end
        end

        -- Fallback: toggling may create/focus a terminal depending on provider.
        require("opencode").toggle()
      end

      local function add_current_file()
        local path

        if vim.bo.filetype == "NvimTree" then
          local ok, lib = pcall(require, "nvim-tree.lib")
          if ok and type(lib.get_node_at_cursor) == "function" then
            local node = lib.get_node_at_cursor()
            if node and node.absolute_path and node.absolute_path ~= "" then
              path = node.absolute_path
            end
          end
        end

        if not path then
          local file = vim.fn.expand("<cfile>")
          if file and file ~= "" then
            path = vim.fn.fnamemodify(file, ":p")
          end
        end

        if not path or path == "" then
          vim.notify("No file under cursor", vim.log.levels.WARN, { title = "opencode" })
          return
        end

        -- Pre-fill a file reference, but let the user add context before sending.
        require("opencode").prompt("@" .. path .. " ")
      end

      local function prompt_current_file_range(mode)
        local path = vim.fn.expand("%:p")
        if not path or path == "" then
          vim.notify("No current file", vim.log.levels.WARN, { title = "opencode" })
          return
        end

        if mode == "visual" then
          local start_line = vim.fn.line("'<")
          local end_line = vim.fn.line("'>")
          if start_line > end_line then
            start_line, end_line = end_line, start_line
          end
          require("opencode").prompt("@" .. path .. " lines " .. start_line .. "-" .. end_line .. " ")
          return
        end

        require("opencode").prompt("@" .. path .. " ")
      end

      -- AI/opencode group (description only)
      vim.keymap.set("n", "<leader>a", "<nop>", vim.tbl_extend("force", opts, { desc = "AI/opencode" }))

      -- Main commands (Codex-compatible-ish)
      vim.keymap.set("n", "<leader>ac", function() require("opencode").toggle() end, vim.tbl_extend("force", opts, { desc = "Toggle opencode" }))
      vim.keymap.set("n", "<leader>af", focus_opencode_terminal, vim.tbl_extend("force", opts, { desc = "Focus opencode" }))
      vim.keymap.set("n", "<leader>ar", function() require("opencode").select_session() end, vim.tbl_extend("force", opts, { desc = "Resume session" }))
      vim.keymap.set("n", "<leader>aC", function() require("opencode").command("session.new") end, vim.tbl_extend("force", opts, { desc = "New session" }))
      vim.keymap.set("n", "<leader>am", function() require("opencode").select() end, vim.tbl_extend("force", opts, { desc = "Select opencode action" }))
      vim.keymap.set("n", "<leader>ab", function() prompt_current_file_range("normal") end, vim.tbl_extend("force", opts, { desc = "Reference current file" }))

      -- Visual mode: send selection/context to opencode
      vim.keymap.set("v", "<leader>as", function() prompt_current_file_range("visual") end, vim.tbl_extend("force", opts, { desc = "Reference selection" }))

      -- File tree / picker buffers: add file under cursor (best-effort)
      vim.api.nvim_create_autocmd("FileType", {
        group = opencodeGroup,
        pattern = { "NvimTree", "neo-tree", "oil", "minifiles" },
        callback = function()
          vim.keymap.set("n", "<leader>as", add_current_file, vim.tbl_extend("force", opts, { desc = "Add file", buffer = true }))
        end,
      })

      -- "Accept / deny" diff equivalents
      vim.keymap.set("n", "<leader>aa", "<cmd>write<cr>", vim.tbl_extend("force", opts, { desc = "Accept (save)" }))
      vim.keymap.set("n", "<leader>ad", function() require("opencode").command("session.undo") end, vim.tbl_extend("force", opts, { desc = "Deny (undo last)" }))
    end,
  }

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
