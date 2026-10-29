-- nvim-only cosmetics on top of the shared ~/.vimrc (loaded by
-- nvim/init.vim): rounded floats, a flash on yank, styled diagnostics and
-- tree-sitter highlighting where a parser ships. No keybindings.
local group = vim.api.nvim_create_augroup('Rice', { clear = true })

-- Rounded borders on every floating window (hover, diagnostics, docs).
vim.o.winborder = 'rounded'

-- Flash whatever was just yanked.
vim.api.nvim_create_autocmd('TextYankPost', {
  group = group,
  callback = function() vim.hl.on_yank({ higroup = 'RiceYank', timeout = 180 }) end,
})

-- Diagnostics: severity icons in the sign column, a dot before inline text.
local sev = vim.diagnostic.severity
vim.diagnostic.config({
  severity_sort = true,
  virtual_text = { prefix = '●', spacing = 2 },
  float = { source = 'if_many' },
  signs = { text = {
    [sev.ERROR] = '\u{f057}', [sev.WARN] = '\u{f071}',
    [sev.INFO] = '\u{f05a}', [sev.HINT] = '\u{f0eb}',
  } },
})

-- Tree-sitter highlighting for any filetype nvim ships a parser for
-- (c, lua, vim, markdown, ...); silently skipped otherwise.
vim.api.nvim_create_autocmd('FileType', {
  group = group,
  callback = function(ev) pcall(vim.treesitter.start, ev.buf) end,
})
