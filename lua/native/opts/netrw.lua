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

local function parent_dir(dir)
  local result, _ = string.gsub(dir, "[^/]*/$", "")
  return result
end

local NETRW_INDENT_WIDTH = 2

-- Returns a mapping of the line number in the netrw tree
-- to the full filename at that line number
---@param bufnr integer buffer number of the neovim window
---@return { [integer]: table } 
local function netrw_tree_line_number_to_file_info(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local running_dirpath = netrw_tree_get_root(bufnr) or vim.fs.normalize(vim.fn.getcwd()) .. "/"
  local prev_indent_level = 0
  local prev_was_dir = false
  local filenames = {}
  for i, line in ipairs(lines) do
    local string_whitespace = string.match(line, "^[%s|]*") or ""
    local curr_indent_level = string.len(string_whitespace)
    -- tree has 
    -- ../
    -- cwd/
    -- | first_dir/
    -- at the top. So only lines one level down are relevant to us.
    if curr_indent_level ~= 0 then
      local indent_difference = prev_indent_level - curr_indent_level
      while (indent_difference > 0 or prev_was_dir and indent_difference >= 0) do
        if prev_was_dir then
          filenames[i - 2].expanded = false
        end
        indent_difference = indent_difference - NETRW_INDENT_WIDTH
        running_dirpath = parent_dir(running_dirpath)
      end
      local maybe_curr_dirname = dirname_if_directory(line)
      if maybe_curr_dirname then
        running_dirpath = running_dirpath .. maybe_curr_dirname
      end
      local filename = maybe_curr_dirname and "" or string.match(line, "[^%s|]*$")
      if not filename then
        error("unreachable: netrw line " .. filename .. " without filename")
      end
      filenames[i - 1] = {
        filename = running_dirpath .. filename,
        directory = not not maybe_curr_dirname,
        expanded = maybe_curr_dirname and true or nil
      }
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


local netrw_extmark_diagnostic_namespace = vim.api.nvim_create_namespace("netrw_extmark_diagnostic_namespace")

local severity_to_hl_group = {
  [vim.diagnostic.severity.HINT] = vim.api.nvim_get_hl_id_by_name("DiagnosticHint"),
  [vim.diagnostic.severity.INFO] = vim.api.nvim_get_hl_id_by_name("DiagnosticInfo"),
  [vim.diagnostic.severity.WARN] = vim.api.nvim_get_hl_id_by_name("DiagnosticWarn"),
  [vim.diagnostic.severity.ERROR] = vim.api.nvim_get_hl_id_by_name("DiagnosticError"),
}

-- local severity_to_underline_hl_group = {
--   [vim.diagnostic.severity.HINT] = vim.api.nvim_get_hl_id_by_name("DiagnosticUnderlineHint"),
--   [vim.diagnostic.severity.INFO] = vim.api.nvim_get_hl_id_by_name("DiagnosticUnderlineInfo"),
--   [vim.diagnostic.severity.WARN] = vim.api.nvim_get_hl_id_by_name("DiagnosticUnderlineWarn"),
--   [vim.diagnostic.severity.ERROR] = vim.api.nvim_get_hl_id_by_name("DiagnosticUnderlineError"),
-- }


local function append_extmark(bufnr, line, ns, text, hl_group)
  vim.api.nvim_buf_set_extmark(bufnr, ns, line, 0, {
    virt_text={
      {text, hl_group}
    },
    priority=2
  })
end

local function draw_diagnostic(bufnr, line, severity)
  append_extmark(bufnr, line, netrw_extmark_diagnostic_namespace, vim.diagnostic.config().signs.text[severity], severity_to_hl_group[severity])
end

vim.api.nvim_set_hl(0, "GitUnstaged", { fg = "#FFFF00" })
vim.api.nvim_set_hl(0, "GitStaged", { fg = "#00FF00" })
vim.api.nvim_set_hl(0, "GitUnmerged", { fg = "#FF0000" })

local netrw_extmark_git_namespace = vim.api.nvim_create_namespace("netrw_extmark_git_namespace")

local function draw_git_icons(bufnr, line, is_unstaged, is_staged, is_unmerged)
  if is_unstaged then
    local hl_id = vim.api.nvim_get_hl_id_by_name("GitUnstaged")
    append_extmark(bufnr, line, netrw_extmark_git_namespace, "M", hl_id)
  end
  if is_staged then
    append_extmark(bufnr, line, netrw_extmark_git_namespace, "A", vim.api.nvim_get_hl_id_by_name("GitStaged"))
  end
  if is_unmerged then
    append_extmark(bufnr, line, netrw_extmark_git_namespace, "󰘭", vim.api.nvim_get_hl_id_by_name("GitUnmerged"))
  end
end

---@param bufnr integer? buffer to populate diagnostics on. nil for all netrw bufs.
local function populate_netrw_diagnostics(bufnr)
  if not bufnr then
    for _, netrw_bufnr in ipairs(get_netrw_tree_buffers()) do
      populate_netrw_diagnostics(netrw_bufnr)
    end
    return
  end

  vim.api.nvim_buf_clear_namespace(bufnr, netrw_extmark_diagnostic_namespace, 0, -1)
  local diagnostics = max_diag_severity_by_file()
  local line_number_to_file_info = netrw_tree_line_number_to_file_info(bufnr)

  for line_num, file_info in pairs(line_number_to_file_info) do
    local filename = file_info.filename
    if diagnostics[filename] then
      draw_diagnostic(bufnr, line_num, diagnostics[filename])
    elseif file_info.expanded == false then
      -- Show nested messages in expanded dirs
      local min_severity = vim.diagnostic.severity.HINT + 1
      for candidate_filename, severity in pairs(diagnostics) do
        if string.find(candidate_filename, "^" .. file_info.filename) and severity < min_severity then
          min_severity = severity
        end
      end
      if min_severity ~= vim.diagnostic.severity.HINT + 1 then
        draw_diagnostic(bufnr, line_num, min_severity)
      end
    end
  end
end

local function split(s, delimiter)
  local result = {}
  for match in string.gmatch(s, "([^"..delimiter.."]+)") do
      table.insert(result, match)
  end
  return result
end

local function to_absolute_paths(relative_paths)
  local result = {}
  for _, path in ipairs(relative_paths) do
    table.insert(result, vim.fs.normalize(vim.fn.fnamemodify(path,":p")))
  end
  return result
end

local function git_unstaged_changes()
  return to_absolute_paths(split(vim.fn.system("git diff --name-only"), "\n"))
end

local function git_staged_changes()
  return to_absolute_paths(split(vim.fn.system("git diff --name-only --staged"), "\n"))
end

local function git_unmerged_changes()
  return to_absolute_paths(split(vim.fn.system("git diff --name-only --diff-filter=U"), "\n"))
end

local function list_to_set(list)
  local set = {}
  for _, val in ipairs(list) do
    set[val] = true
  end
  return set
end


local function populate_netrw_git_icons(bufnr)
  if not bufnr then
    for _, netrw_bufnr in ipairs(get_netrw_tree_buffers()) do
      populate_netrw_git_icons(netrw_bufnr)
    end
    return
  end

  vim.api.nvim_buf_clear_namespace(bufnr, netrw_extmark_git_namespace, 0, -1)
  local unstaged = list_to_set(git_unstaged_changes())
  local staged = list_to_set(git_staged_changes())
  local unmerged = list_to_set(git_unmerged_changes())

  local line_number_to_file_info = netrw_tree_line_number_to_file_info(bufnr)

  for line_num, file_info in pairs(line_number_to_file_info) do
    local filename = file_info.filename
    draw_git_icons(bufnr, line_num, unstaged[filename], staged[filename], unmerged[filename])
  end
end

vim.diagnostic.handlers["netrw/redraw_diagnostics"] = {
  show = function(_, _, _, _)
    populate_netrw_diagnostics()
    populate_netrw_git_icons()
  end,
  hide = function(_, _)
    populate_netrw_diagnostics()
    populate_netrw_git_icons()
  end
}

vim.api.nvim_create_autocmd("FileType", {
  pattern="netrw",
  callback = function()
    populate_netrw_diagnostics()
    populate_netrw_git_icons()
  end
})

vim.api.nvim_create_autocmd("BufWritePost", {
  pattern="*",
  callback = function()
    populate_netrw_git_icons()
  end
})
