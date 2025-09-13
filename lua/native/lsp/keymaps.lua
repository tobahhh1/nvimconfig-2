-- LSP keymaps
local function goto_definition()
  local clients = vim.lsp.get_clients()
  if clients and #clients > 0 then
    vim.lsp.buf.definition()
  else
    vim.cmd("normal gd")
  end
end

vim.keymap.set("n", "gd", goto_definition, { noremap = true, desc = "LSP goto definition" })
