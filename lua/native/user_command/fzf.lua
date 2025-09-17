-- Custom fzf commands

local function get_unique(arr)
  local seen = {}
  local out = {}
  for _, value in ipairs(arr) do
    if not seen[value] then
      seen[value] = true
      table.insert(out, value)
    end
  end
  return out
end

local function find_helptags()
  local tagfiles = vim.fn.sort(
    vim.fn.split(vim.fn.globpath(vim.o.runtimepath, 'doc/tags', true), '\n')
  )
  local tags = {}
  for _, path in ipairs(tagfiles) do
    local file = io.open(path, 'r')
    if not file then
      error("File " .. file .. " not found")
    end
    for line in file:lines() do
      table.insert(tags, vim.fn.split(line, '\t')[1])
    end
  end
  return get_unique(tags)
end

local function fzf_wrap_and_run(args)
  vim.fn['fzf#run'](vim.fn['fzf#wrap'](args))
end

local function fzf_search_help()
  local helptags = find_helptags()
  fzf_wrap_and_run({
    source = helptags,
    sink = 'help',
    window="0",
  })
end

vim.api.nvim_create_user_command('FZFHelp', fzf_search_help, {})
vim.keymap.set('n', '<leader>sh', fzf_search_help, { silent = true })

local function fzf_search_files()
  fzf_wrap_and_run({
    sink = 'e',
    options = '--preview "cat {}" --preview-window=down,40%',
    window = "0"
  })
end

vim.api.nvim_create_user_command('FZFFiles', fzf_search_files, {})
vim.keymap.set('n', '<leader>sf', fzf_search_files, { silent = true })
