-- Diagnostic settings
vim.diagnostic.config({
  virtual_text = true,
  signs = {
    text = {
      [vim.diagnostic.severity.HINT] = vim.g.have_nerd_font and '' or 'H',
      [vim.diagnostic.severity.INFO] = vim.g.have_nerd_font and '' or 'I',
      [vim.diagnostic.severity.WARN] = vim.g.have_nerd_font and '' or 'W',
      [vim.diagnostic.severity.ERROR] = vim.g.have_nerd_font and '' or 'E',
    }
  },
  severity_sort = true,
  ["netrw/redraw_diagnostics"] = {}
})

