vim.o.splitright = true

vim.api.nvim_create_user_command("Vthird", function()
  local desired_width = math.floor(vim.o.columns / 3)
  vim.cmd("vsplit")
  vim.api.nvim_win_set_width(0, desired_width)
end, {})

vim.keymap.set({"n", "v"}, "<C-w>V", "<cmd>Vthird<cr>", {silent = true})
