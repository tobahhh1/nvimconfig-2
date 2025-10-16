
local function add_file_to_copilot()
  vim.cmd("wincmd p")
  local filepath = vim.api.nvim_buf_get_name(0)
  if filepath == "" then
    vim.notify("No file in current buffer", vim.log.levels.WARN)
    return
  end
  vim.cmd("wincmd p")
  vim.fn.chansend(vim.b.terminal_job_id, "@" .. filepath .. "\n")
end

local function open_copilot_window()
  local bufnr = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_win_set_buf(0, bufnr)
  vim.fn.jobstart("copilot", { term = true })
  vim.cmd("startinsert")
  vim.bo[bufnr].filetype = "copilot"
  vim.keymap.set("n", "<leader>if", add_file_to_copilot, { buffer = true })
end

vim.api.nvim_create_user_command("CliCopilotOpen", open_copilot_window, {})
vim.api.nvim_create_user_command("CliCopilotAddFile", add_file_to_copilot, {})
vim.keymap.set("n", "<leader>ac", "<cmd>CliCopilotOpen<CR>", { silent = true })
vim.keymap.set("n", "<leader>bac", "<cmd>Vthird CliCopilotOpen<CR>", {silent = true})
