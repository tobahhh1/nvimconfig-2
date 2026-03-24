vim.lsp.config("pyright", {
  settings = {
    python = {
      analysis = {
        autoSearchPaths = false,
        diagnosticMode = "workspace",
      },
    },
  }
})
vim.lsp.enable("pyright")
