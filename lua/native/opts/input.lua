
local default_normal_text_hl = vim.api.nvim_get_hl(0, { name = "Normal"})
local default_win_separator_hl = vim.api.nvim_get_hl(0, { name = "WinSeparator"})

vim.api.nvim_set_hl(
  0,
  "FloatBorder",
  {
    fg = default_win_separator_hl.bg,
    bg = default_normal_text_hl.bg
  }
)

vim.api.nvim_set_hl(
  0,
  "NormalFloat",
  {
    fg = default_normal_text_hl.fg,
    bg = default_normal_text_hl.bg
  }
)

vim.g.input_prompt = " "
vim.g.input_window_start_width = 5

-- All prompts will be sent through this function
vim.ui.input = function(opts, on_confirm)
  local buf = vim.api.nvim_create_buf(false, true)

  local function get_width()
    local text = vim.api.nvim_get_current_line()
    return math.max(#opts.prompt + 4, vim.g.input_window_start_width, #(vim.g.input_prompt .. text) + 2)
  end

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "cursor",
    width = get_width(),
    height = 1,
    col = 0,
    row = -3,
    style = "minimal",
    border = "rounded",
    title = opts.prompt,
    title_pos = "center"
  })

  vim.bo[buf].buftype = "prompt"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "PromptInput"

  local function cleanup ()
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  vim.keymap.set("n", "<ESC>", function ()
    cleanup()
    on_confirm(nil)
  end, { buffer = true })

  vim.fn.prompt_setprompt(buf, " ")
  vim.fn.prompt_setcallback(buf, function(input)
    cleanup()
    on_confirm(input)
  end)

  local handle_text_changed = function()
    vim.bo[buf].modified = false
    local new_width = get_width()
    vim.api.nvim_win_set_width(win, new_width)
    -- recenter window
    vim.api.nvim_win_set_config(win, {
      width = new_width,
    })
  end

  vim.api.nvim_create_autocmd("TextChangedI", {
    buffer = buf,
    callback = handle_text_changed
  })

  vim.api.nvim_create_autocmd("TextChanged", {
    buffer = buf,
    callback = handle_text_changed
  })

  vim.cmd.startinsert()
end
