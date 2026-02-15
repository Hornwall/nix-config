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

-- vim.lsp.config("solargraph", {
--   capabilities = capabilities,
-- })
-- vim.lsp.enable("solargraph")

-- Standardrb
vim.opt.signcolumn = "yes" -- otherwise it bounces in and out, not strictly needed though
vim.api.nvim_create_autocmd("FileType", {
  pattern = "ruby",
  group = vim.api.nvim_create_augroup("RubyLSP", { clear = true }), -- also this is not /needed/ but it's good practice 
  callback = function()
    vim.lsp.start {
      name = "standard",
      cmd = { "standardrb", "--lsp" },
    }
  end,
})
