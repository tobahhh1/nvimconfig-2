-- Custom fzf commands

vim.g.fzf_preview_window_opt = "down,60%"
vim.g.fzf_preview_num_lines = 10

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

local function fzf_wrap_and_run(...)
  vim.fn['fzf#run'](vim.fn['fzf#wrap'](...))
end

local function fzf_search_help()
  local helptags = find_helptags()
  fzf_wrap_and_run("help", {
    source = helptags,
    sink = 'help',
    window="enew",
  }, 0)
end

vim.api.nvim_create_user_command('FZFHelp', fzf_search_help, {})
vim.keymap.set('n', '<leader>sh', fzf_search_help, { silent = true })
vim.keymap.set("n", "<leader>bsh", "<cmd>Vthird FZFHelp<CR>", {silent = true})

local function fzf_search_files()
  fzf_wrap_and_run("files", {
    sink = 'e',
    options = '--preview "bat --color=always {}" --preview-window=' .. vim.g.fzf_preview_window_opt .. ' --ansi',
    window = "enew"
  }, 0)
end

vim.api.nvim_create_user_command('FZFFiles', fzf_search_files, {})
vim.keymap.set('n', '<leader>sf', fzf_search_files, { silent = true })
vim.keymap.set("n", "<leader>bsf", "<cmd>Vthird FZFFiles<CR>", {silent = true})

local function fzf_search_ripgrep_sink(selected_opt)
  local split_colon = string.gmatch(selected_opt, "[^:]+")
  local file = split_colon()
  local line = split_colon()
  vim.cmd("e +" .. line .. " " .. file)
end

local function fzf_search_ripgrep()
  local rg_prefix = "rg --column --line-number --no-heading --color=always --smart-case"
  local options = ""
  options = options .. '--preview \'LINE={2};LINERANGEBOTTOM=$((LINE-' .. vim.g.fzf_preview_num_lines .. '));LINEMIN=$([ 0 -ge $LINERANGEBOTTOM ] && echo "0" || echo "$LINERANGEBOTTOM"); bat --color=always --highlight-line {2} --line-range=$LINEMIN:$((LINE+' .. vim.g.fzf_preview_num_lines .. ')) {1}\' '
  options = options .. '--preview-window=' .. vim.g.fzf_preview_window_opt .. ' '
  options = options .. '--bind "start:reload:' .. rg_prefix .. ' {q}" '
  options = options .. '--bind "change:reload:' .. rg_prefix .. ' {q} || true" '
  options = options .. '--delimiter : '
  options = options .. '--ansi --disabled '
  options = options .. '--print-query '
  fzf_wrap_and_run("grep", {
    source = {},
    options = options,
    ['sink*'] = function(results)
      if #results < 2 then return end
      local query = results[1]
      local selected = results[2]
      fzf_search_ripgrep_sink(selected)
      if query and query ~= '' then
        vim.fn.setreg('/', query)
        vim.o.hlsearch = true
      end
    end,
    window = 'enew'
  }, 0)
end


vim.api.nvim_create_user_command('FZFGrep', fzf_search_ripgrep, {})
vim.keymap.set('n', '<leader>sg', fzf_search_ripgrep, { silent = true})
vim.keymap.set("n", "<leader>bsg", "<cmd>Vthird FZFGrep<CR>", {silent = true})

vim.g.fzf_history_dir = '~/.local/share/fzf-history'
vim.g.fzf_action = {
  ['ctrl-t'] = 'tab split',
  ['ctrl-x'] = 'split',
  ['ctrl-v'] = 'vsplit'
}
