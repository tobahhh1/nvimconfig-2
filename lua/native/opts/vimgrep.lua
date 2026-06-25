local pending_pattern = nil
local pending_grep_pattern = nil

local function extract_vimgrep_pattern(rest)
  if not rest or rest == "" then return nil end
  local delim = rest:sub(1, 1)
  local pattern

  if delim:match("%W") and not delim:match("%s") then
    -- Delimited form: /pattern/[flags]
    -- Manually scan so that backslash-escaped delimiters (e.g. \/) are not
    -- treated as the closing delimiter.
    local i = 2
    local chars = {}
    while i <= #rest do
      local c = rest:sub(i, i)
      if c == "\\" and i < #rest then
        table.insert(chars, c)
        table.insert(chars, rest:sub(i + 1, i + 1))
        i = i + 2
      elseif c == delim then
        break
      else
        table.insert(chars, c)
        i = i + 1
      end
    end
    pattern = table.concat(chars)
  else
    -- Undelimited form: pattern is the first whitespace-separated token
    pattern = rest:match("^(%S+)")
  end

  return (pattern ~= "" and pattern) or nil
end

vim.api.nvim_create_autocmd("CmdlineLeave", {
  callback = function()
    pending_pattern = nil
    pending_grep_pattern = nil
    if vim.fn.getcmdtype() ~= ":" then return end
    local cmdline = vim.fn.getcmdline()

    -- Match vimgrep / vimgrepadd and their abbreviations
    local rest = cmdline:match("^%s*vim?g?r?e?p?a?d?d?!?%s+(.*)")
    pending_pattern = extract_vimgrep_pattern(rest)

    -- Match :grep / :grepadd (but not :vimgrep / :vimgrepadd)
    local grep_rest = cmdline:match("^%s*grepa?d?d?!?%s+(.*)")
    pending_grep_pattern = grep_rest and grep_rest:match("^(%S+)") or nil
  end,
})

vim.api.nvim_create_autocmd("QuickFixCmdPost", {
  pattern = { "vimgrep", "vimgrepadd" },
  callback = function()
    if not pending_pattern then return end
    vim.fn.setreg("/", pending_pattern)
    vim.opt.hlsearch = true
    pending_pattern = nil
  end,
})

vim.api.nvim_create_autocmd("QuickFixCmdPost", {
  pattern = { "grep", "grepadd" },
  callback = function()
    if not pending_grep_pattern then return end
    vim.fn.setreg("/", "\\v" .. pending_grep_pattern)
    vim.opt.hlsearch = true
    pending_grep_pattern = nil
  end,
})

vim.o.grepprg="rg --vimgrep"
vim.o.grepformat="%f:%l:%c:%m"
