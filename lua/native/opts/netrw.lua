vim.g.netrw_liststyle = 3
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 30

vim.keymap.set('n', '\\', '<cmd>Lex!<cr>')


-- Returns a lookup table where, if a file has diagnostics,
-- it will be an entry in the table, and the most severe diagnostic
-- message is displayed.
local function max_diag_severity_by_file()
  local lookup = {}
  for _, d in ipairs(vim.diagnostic.get()) do
    local fname = vim.api.nvim_buf_get_name(d.bufnr)
    if fname ~= "" then
      fname = vim.fs.normalize(fname)
      local severity = lookup[fname] or vim.diagnostic.severity.HINT + 1
      if d.severity < severity then
        lookup[fname] = d.severity
      end
    end
  end
  return lookup
end


local function dirname_if_directory(filename)
  return string.match(filename, "[^%s|]*/$")
end

local function is_netrw_tree(bufnr)
  return not not string.find(vim.api.nvim_buf_get_name(bufnr), "NetrwTreeListing$")
end

local function netrw_tree_get_root(_)
  -- TODO: Currently there is no way of getting the root of the tree based on what is displaying.
  -- This means this script does not support changing the root of the tree with gn or ../
  return nil
end

-- Returns a mapping of the line number in the netrw tree
-- to the full filename at that line number
---@param bufnr integer buffer number of the neovim window
---@return { [integer]: string } 
local function netrw_tree_line_number_to_filename(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local running_dirpath = netrw_tree_get_root(bufnr) or vim.fs.normalize(vim.fn.getcwd()) .. "/"
  local prev_indent_level = 0
  local prev_was_dir = false
  local filenames = {}
  for i, line in ipairs(lines) do
    local string_whitespace = string.match(line, "^[%s|]*") or ""
    -- tree has 
    -- ../
    -- cwd/
    -- at the top, so skip that.
    local curr_indent_level = string.len(string_whitespace)
    if curr_indent_level ~= 0 then
      if curr_indent_level < prev_indent_level or (prev_was_dir and curr_indent_level == prev_indent_level) then
        -- remove last directory from dirpath
        running_dirpath, _ = string.gsub(running_dirpath, "[^/]*/$", "")
      end
      local maybe_curr_dirname = dirname_if_directory(line)
      if maybe_curr_dirname then
        running_dirpath = running_dirpath .. maybe_curr_dirname
      end
      local filename = maybe_curr_dirname and "" or string.match(line, "[^%s|]*$")
      if not filename then
        error("unreachable: netrw line " .. filename .. " without filename")
      end
      filenames[i - 1] = running_dirpath .. filename
      prev_was_dir = maybe_curr_dirname and true or false
      prev_indent_level = curr_indent_level
    end
  end
  return filenames
end

local function get_netrw_tree_buffers()
  local result = {}
  for _, buf in ipairs(vim.fn.getbufinfo()) do
    if is_netrw_tree(buf.bufnr) then
      table.insert(result, buf.bufnr)
      end
  end
  return result
end


local netrw_extmark_namespace = vim.api.nvim_create_namespace("netrw_extmark_namespace")

local severity_to_hl_group = {
  [vim.diagnostic.severity.HINT] = vim.api.nvim_get_hl_id_by_name("DiagnosticHint"),
  [vim.diagnostic.severity.INFO] = vim.api.nvim_get_hl_id_by_name("DiagnosticInfo"),
  [vim.diagnostic.severity.WARN] = vim.api.nvim_get_hl_id_by_name("DiagnosticWarn"),
  [vim.diagnostic.severity.ERROR] = vim.api.nvim_get_hl_id_by_name("DiagnosticError"),
}

local function draw_diagnostic(bufnr, line, col, severity)
  vim.api.nvim_buf_set_extmark(bufnr, netrw_extmark_namespace, line, col, {
    virt_text={
      {vim.diagnostic.config().signs.text[severity], severity_to_hl_group[severity]}
    },
    virt_text_pos = "overlay",
  })
end

---@param bufnr integer? buffer to populate diagnostics on. nil for all netrw bufs.
local function populate_netrw_diagnostics(bufnr)
  if not bufnr then
    for _, netrw_bufnr in ipairs(get_netrw_tree_buffers()) do
      populate_netrw_diagnostics(netrw_bufnr)
    end
    return
  end

  vim.api.nvim_buf_clear_namespace(bufnr, netrw_extmark_namespace, 0, -1)
  local diagnostics = max_diag_severity_by_file()
  local line_number_to_filename = netrw_tree_line_number_to_filename(bufnr)

  for line_num, filename in pairs(line_number_to_filename) do
    if diagnostics[filename] then
      draw_diagnostic(bufnr, line_num, 0, diagnostics[filename])
    end
  end
end
populate_netrw_diagnostics()

vim.diagnostic.handlers["netrw/redraw_diagnostics"] = {
  show = function(_, _, _, _)
    populate_netrw_diagnostics()
  end,
  hide = function(_, _)
    populate_netrw_diagnostics()
  end
}

vim.api.nvim_create_autocmd("FileType", {
  pattern="*",
  callback = function()
    if vim.bo.filetype == "netrw" then
      populate_netrw_diagnostics()
    end
  end
})
