-- Setup for nvim-treesitter
-- This plugin, while maintained externally by the community,
-- is officially supported by Neovim and mentioned multiple times in the default 
-- helpdocs. Seems safe.
require('nvim-treesitter.configs').setup {
  ensure_installed = { "java", "lua" }
}

require('tbrow').setup({})

