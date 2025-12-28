local tbrow_file_api = require("tbrow").api.file

local M = {}

function M.create_file(switch_to_new_file)
  local winnr = vim.api.nvim_get_current_win()
  local directory_under_cursor = tbrow_file_api.directory_under_cursor(winnr)
  local base_file_path
  if directory_under_cursor == nil then
    base_file_path = vim.fn.getcwd()
  else
    base_file_path = directory_under_cursor
  end
  vim.ui.input({ prompt = "Enter new file name: ", default = base_file_path }, function(input)
    if input == nil or input == "" then
      print("File creation cancelled.")
      return
    end
    local new_file_path = vim.fn.fnamemodify(input, ":p")
    local file = io.open(new_file_path, "w")
    if file == nil then
      print("Error creating file: " .. new_file_path)
      return
    end
    file:close()
    if switch_to_new_file then
      vim.cmd("edit " .. new_file_path)
    end
    print("File created: " .. new_file_path)
  end)
end

function M.delete_file()
  local winnr = vim.api.nvim_get_current_win()
  local file_under_cursor = tbrow_file_api.file_under_cursor(winnr)
  local base_file_path
  if file_under_cursor == nil then
    base_file_path = vim.api.nvim_buf_get_name(0)
    if base_file_path == "" then
      base_file_path = vim.fn.getcwd()
    end
  else
    base_file_path = file_under_cursor
  end
  vim.ui.input({ prompt = "Enter file name to delete:", default = base_file_path }, function(input)
    if input == nil or input == "" then
      print("File deletion cancelled.")
      return
    end
    vim.ui.input({ prompt = "Are you sure you want to delete " .. input .. "? (y/n): " }, function(confirm)
      if confirm ~= "y" then
        print("File deletion cancelled.")
        return
      end
      local delete_file_path = vim.fn.fnamemodify(input, ":p")
      local result, err = os.remove(delete_file_path)
      if result == nil then
        print("Error deleting file: " .. err)
        return
      end
      print("File deleted: " .. delete_file_path)
    end)
  end)
end

function M.rename_file()
  local winnr = vim.api.nvim_get_current_win()
  local file_under_cursor = tbrow_file_api.file_under_cursor(winnr)
  local open_file = vim.api.nvim_buf_get_name(0)
  local base_file_path
  if file_under_cursor == nil then
    base_file_path = open_file
    if base_file_path == "" then
      base_file_path = vim.fn.getcwd()
    end
  else
    base_file_path = file_under_cursor
  end
  vim.ui.input({ prompt = "Enter existing file name to rename:", default = base_file_path }, function(current_name)
    if current_name == nil or current_name == "" then
      print("File renaming cancelled.")
      return
    end
    vim.ui.input({ prompt = "Enter new file name:", default = current_name }, function(new_name)
      if new_name == nil or new_name == "" then
        print("File renaming cancelled.")
        return
      end
      local current_file_path = vim.fn.fnamemodify(current_name, ":p")
      local new_file_path = vim.fn.fnamemodify(new_name, ":p")
      local result, err = os.rename(current_file_path, new_file_path)
      if result == nil then
        print("Error renaming file: " .. err)
        return
      end
      print("File renamed from " .. current_file_path .. " to " .. new_file_path)
      if open_file == current_file_path then
        vim.cmd("edit " .. new_file_path)
      end
    end)
  end)
end

vim.api.nvim_create_user_command("CreateFile", M.create_file, { bang = true })
vim.api.nvim_create_user_command("DeleteFile", M.delete_file, {})
vim.api.nvim_create_user_command("RenameFile", M.rename_file, {})

vim.api.nvim_set_keymap("n", "<leader>fc", "<cmd>CreateFile<cr>", { silent = true })
vim.api.nvim_set_keymap("n", "<leader>fd", "<cmd>DeleteFile<cr>", { silent = true })
vim.api.nvim_set_keymap("n", "<leader>>fm", "<cmd>RenameFile<cr>", { silent = true })
vim.api.nvim_set_keymap("n", "<leader>fC", "<cmd>CreateFile!<cr>", { silent = true })

return M
