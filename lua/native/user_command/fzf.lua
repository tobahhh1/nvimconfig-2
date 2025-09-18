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
    window="enew",
  })
end

vim.api.nvim_create_user_command('FZFHelp', fzf_search_help, {})
vim.keymap.set('n', '<leader>sh', fzf_search_help, { silent = true })

local function fzf_search_files()
  fzf_wrap_and_run({
    sink = 'e',
    options = '--preview "bat --color=always {}" --preview-window=down,40% --ansi',
    window = "enew"
  })
end

vim.api.nvim_create_user_command('FZFFiles', fzf_search_files, {})
vim.keymap.set('n', '<leader>sf', fzf_search_files, { silent = true })

vim.g.fzf_ripgrep_debounce = '0.05'


local function fzf_search_ripgrep_sink(selected_opt)
  local split_colon = string.gmatch(selected_opt, "[^:]+")
  local file = split_colon()
  local line = split_colon()
  vim.cmd("e +" .. line .. " " .. file)
end

local function fzf_search_ripgrep()
  local rg_prefix = "rg --column --line-number --no-heading --color=always --smart-case"
  local options = ""
  options = options .. '--preview "bat --color=always {1} --highlight-line {2}" '
  options = options .. '--preview-window=down,40% '
  options = options .. '--bind "start:reload:' .. rg_prefix .. ' {q}" '
  options = options .. '--bind "change:reload:sleep ' .. vim.g.fzf_ripgrep_debounce .. '; ' .. rg_prefix .. ' {q} || true" '
  options = options .. '--delimiter : '
  options = options .. '--ansi --disabled '
  fzf_wrap_and_run({
    source = {},
    options = options,
    sink = fzf_search_ripgrep_sink,
    window = 'enew'
  })
end


vim.api.nvim_create_user_command('FZFGrep', fzf_search_ripgrep, {})
vim.keymap.set('n', '<leader>sg', fzf_search_ripgrep, { silent = true})
