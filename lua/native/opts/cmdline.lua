
local state = { buf = nil, win = nil }

local function get_text()
  return vim.fn.getcmdtype() .. vim.fn.getcmdline()
end

local function get_width(text)
  return math.max(vim.g.input_window_start_width, #text + 4)
end

local function open_window()
  local text = get_text()
  local width = get_width(text)

  state.buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, { text })

  state.win = vim.api.nvim_open_win(state.buf, false, {
    relative = "cursor",
    width = width,
    height = 1,
    col = 0,
    row = -3,
    style = "minimal",
    border = "rounded",
    focusable = false,
  })
  vim.cmd("redraw")
end

local function update_window()
  if not (state.win and vim.api.nvim_win_is_valid(state.win)) then
    return
  end
  local text = get_text()
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, { text })
  vim.api.nvim_win_set_width(state.win, get_width(text))
  vim.cmd("redraw")
end

local function close_window()
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    vim.api.nvim_buf_delete(state.buf, { force = true })
  end
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  state.buf = nil
  state.win = nil
end

vim.api.nvim_create_autocmd("CmdlineEnter", { callback = function() vim.schedule(open_window) end })
vim.api.nvim_create_autocmd("CmdlineChanged", { callback = function() vim.schedule(update_window) end })
vim.api.nvim_create_autocmd("CmdlineLeave", { callback = close_window })
