local capabilities = require("cmp_nvim_lsp").default_capabilities(
  vim.lsp.protocol.make_client_capabilities()
)

local function map_keys(bufnr)
  vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = bufnr })
  vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = bufnr })
  vim.keymap.set("n", "gt", vim.lsp.buf.type_definition, { buffer = bufnr })
  vim.keymap.set("n", "gi", vim.lsp.buf.implementation, { buffer = bufnr })
  vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, { buffer = bufnr })
  vim.keymap.set("n", "<leader>dj", vim.diagnostic.goto_next, { buffer = bufnr })
  vim.keymap.set("n", "<leader>dk", vim.diagnostic.goto_prev, { buffer = bufnr })
  vim.keymap.set("n", "<leader>dl", "<cmd>Telescope diagnostics<cr>", { buffer = bufnr })
  vim.keymap.set("n", "<leader>tr", "<cmd>Telescope lsp_references<cr>", { buffer = bufnr })
end

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("LspKeymaps", { clear = true }),
  callback = function(args)
    map_keys(args.buf)
  end,
})

vim.lsp.config("volar", {
  capabilities = capabilities,
})
vim.lsp.enable("volar")

vim.lsp.config("ts_ls", {
  capabilities = capabilities,
})
vim.lsp.enable("ts_ls")

local function has_devenv(root_dir)
  if not root_dir then
    return false
  end

  return vim.uv.fs_stat(root_dir .. "/devenv.nix") ~= nil
    or vim.uv.fs_stat(root_dir .. "/devenv.yaml") ~= nil
end

local function start_ruby_server(dispatchers, config, project_command, fallback_command, fallback_env)
  local command = fallback_command
  local spawn_options = {
    cwd = config.root_dir,
    env = fallback_env,
  }

  if has_devenv(config.root_dir) then
    -- Do not leak Neovim's Nix Ruby provider environment into devenv.
    command = {
      "env",
      "-u", "GEM_HOME",
      "-u", "GEM_PATH",
      "-u", "BUNDLE_GEMFILE",
      "devenv", "-q", "shell",
    }
    vim.list_extend(command, project_command)
    spawn_options.env = nil
  end

  return vim.lsp.rpc.start(command, dispatchers, spawn_options)
end

vim.lsp.config("ruby_lsp", {
  cmd = function(dispatchers, config)
    return start_ruby_server(
      dispatchers,
      config,
      { "bundle", "exec", "ruby-lsp" },
      { "ruby-lsp" },
      {
        GEM_HOME = vim.fn.stdpath("data") .. "/ruby-lsp/gems",
        GEM_PATH = "",
      }
    )
  end,
  capabilities = capabilities,
  init_options = {
    -- StandardRB handles formatting in the separate client below.
    formatter = "none",
  },
})
vim.lsp.enable("ruby_lsp")

vim.lsp.config("standardrb", {
  cmd = function(dispatchers, config)
    return start_ruby_server(
      dispatchers,
      config,
      { "bundle", "exec", "standardrb", "--lsp" },
      { "standardrb", "--lsp" }
    )
  end,
})
vim.lsp.enable("standardrb")

vim.opt.signcolumn = "yes" -- otherwise it bounces in and out
