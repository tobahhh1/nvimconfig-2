
local function fzf_wrap_and_run(args)
  vim.fn['fzf#run'](vim.fn['fzf#wrap'](args))
end

vim.g.min_custom_select_height = 16
vim.g.min_custom_select_width = 48

vim.ui.select = function(items, opts, on_choice)

  local cursor = vim.api.nvim_win_get_cursor(0)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"

  local formatted_items = {}
  local width = vim.g.min_custom_select_width
  for i, item in ipairs(items) do
    local line = tostring(i) .. ". " .. opts.format_item(item)
    width = math.max(width, #line + 3)
    table.insert(formatted_items, line)
  end

  local height = math.min(#items + 2, vim.g.min_custom_select_height)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "cursor",
    width = width,
    height = vim.g.min_custom_select_height,
    col = 0,
    row = cursor[1] - height - 2 > 0 and -height - 2 or 1,
    style = "minimal",
    border = "rounded",
    title = opts.prompt,
    title_pos = "center"
  })

  local function cleanup ()
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  local function get_idx(item)
    local match = string.match(item, "^[0-9]+")
    if match ~= nil then
      return tonumber(match)
    end
    error("Item must begin with a number")
  end

  local function choose_item(item)
    on_choice(items[get_idx(item)])
    cleanup()
  end

  vim.keymap.set("n", "<ESC>", function ()
    on_choice(nil)
    cleanup()
  end, { buffer = true })


  fzf_wrap_and_run({
    source = formatted_items,
    sink = choose_item,
    window = '0',
  })

end
