
local function open_copilot_window()
  local bufnr = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_win_set_buf(0, bufnr)
  vim.fn.jobstart("copilot", { term = true })
  vim.cmd("startinsert")
  vim.bo[bufnr].filetype = "copilot"
end

vim.api.nvim_create_user_command("CliCopilotOpen", open_copilot_window, {})
vim.keymap.set("n", "<leader>ac", "<cmd>CliCopilotOpen<CR>", { silent = true })
vim.keymap.set("n", "<leader>bac", "<cmd>Vthird CliCopilotOpen<CR>", {silent = true})
