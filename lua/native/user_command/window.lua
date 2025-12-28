vim.o.splitright = true
vim.o.splitbelow = true

local function vthird(obj)
  local desired_width = math.floor(vim.o.columns / 3)
  vim.cmd("vsplit")
  vim.api.nvim_win_set_width(0, desired_width)
  if obj.args ~= "" then
    vim.cmd(obj.args)
  end
end

vim.api.nvim_create_user_command("Vthird", vthird, { nargs = "*" })
vim.keymap.set({"n", "v"}, "<C-w>V", "<cmd>Vthird<cr>", {silent = true})

local function hthird(obj)
  local desired_height = math.floor(vim.o.lines / 3)
  vim.cmd("split")
  vim.api.nvim_win_set_height(0, desired_height)
  if obj.args ~= "" then
    vim.cmd(obj.args)
  end
end
vim.api.nvim_create_user_command("Hthird", hthird, { nargs = "*" })
vim.keymap.set({"n", "v"}, "<C-w>S", "<cmd>Hthird<cr>", {silent = true})
