local capabilities = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())

function map_keys()
  vim.keymap.set("n", "K", vim.lsp.buf.hover, {buffer=0})
  vim.keymap.set("n", "gd", vim.lsp.buf.definition, {buffer=0})
  vim.keymap.set("n", "gt", vim.lsp.buf.type_definition, {buffer=0})
  vim.keymap.set("n", "gi", vim.lsp.buf.implementation, {buffer=0})
  vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, {buffer=0})
  vim.keymap.set("n", "<leader>dj", vim.diagnostic.goto_next, {buffer=0})
  vim.keymap.set("n", "<leader>dk", vim.diagnostic.goto_prev, {buffer=0})
  vim.keymap.set("n", "<leader>dl", "<cmd>Telescope diagnostics<cr>", {buffer=0})
  vim.keymap.set("n", "<leader>tr", "<cmd>Telescope lsp_references<cr>", {buffer=0})
end

require("lspconfig").volar.setup{
  capabilities = capabilities,
  on_attach = function()
    map_keys()
  end,
} -- connect to solargraph

require("lspconfig").tsserver.setup{
  capabilities = capabilities,
  on_attach = function()
    map_keys()
  end,
} -- connect to solargraph

require("lspconfig").solargraph.setup{
  capabilities = capabilities,
  on_attach = function()
    map_keys()
  end,
} -- connect to solargraph
