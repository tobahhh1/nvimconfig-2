vim.o.splitright = true
vim.g.tray_width = 50

vim.api.nvim_create_user_command("Tray", function()
  vim.cmd("vsplit")
  vim.api.nvim_win_set_width(0, vim.g.tray_width)
end, {})

