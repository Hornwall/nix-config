local cmp = require("cmp")
local luasnip = require("luasnip")

local has_words_before = function()
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

vim.opt.completeopt = {
   "menu",
   "menuone",
   "noselect",
}

cmp.setup({
 snippet = {
   expand = function(args)
     require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
   end,
 },
 completion = {
   autocomplete = false,
 },
 mapping = {
   ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      elseif has_words_before() then
        cmp.complete()
      else
        fallback()
      end
    end, { "i", "s" }),

    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { "i", "s" }),
   ['<C-b>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i', 'c' }),
   ['<C-f>'] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i', 'c' }),
   ['<C-Space>'] = cmp.mapping(cmp.mapping.complete(), { 'i', 'c' }),
   ['<C-y>'] = cmp.config.disable, -- Specify `cmp.config.disable` if you want to remove the default `<C-y>` mapping.
   ['<C-e>'] = cmp.mapping({
     i = cmp.mapping.abort(),
     c = cmp.mapping.close(),
   }),
   ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
 },
 sources = cmp.config.sources({
   { name = 'nvim_lsp' },
   { name = 'luasnip' }, -- For luasnip users.
 }, {
   { name = 'buffer' },
 })
})

-- Set configuration for specific filetype.
cmp.setup.filetype('gitcommit', {
 sources = cmp.config.sources({
   { name = 'cmp_git' }, -- You can specify the `cmp_git` source if you were installed it. 
 }, {
   { name = 'buffer' },
 })
})
