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

vim.api.nvim_create_user_command("DiagnosticsToQuickfix", function(opts)
  if #opts.fargs == 0 then
    vim.diagnostic.setqflist({ open = true })
  else
    -- pass severity of each argument to a table
    local diagnostic_severities = {}
    for _, arg in ipairs(opts.fargs) do
      local severity = vim.diagnostic.severity[string.upper(arg)]
      if severity then
        table.insert(diagnostic_severities, severity)
      else
        print("Invalid severity: " .. arg)
        return
      end
    end
    vim.diagnostic.setqflist({ open = true, severity = diagnostic_severities })
  end
end, { nargs = "*" })

vim.api.nvim_set_keymap('n', '<leader>qd', ':DiagnosticsToQuickfix<CR>', { noremap = true, silent = true })
