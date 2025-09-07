vim.o.completeopt = "fuzzy,menu,menuone,noinsert,popup"


-- Display autocomplete window
vim.keymap.set('i', '<C-Space>', '<C-x><C-o>', {})


local function tab_complete()
	if vim.fn.pumvisible() == 1 then
		return "<C-n>"
	else
		return "<Tab>"
	end
end

local function s_tab_complete()
	if vim.fn.pumvisible() == 1 then
		return "<C-p>"
	else
		return "<S-Tab>"
	end
end

local function cr_complete()
	if vim.fn.pumvisible() == 1 then
		return "<C-y>"
	else
		return "<CR>"
	end
end

-- Next completion item
vim.keymap.set('i', '<Tab>', tab_complete, { expr = true })
-- Previous completion item
vim.keymap.set('i', '<S-Tab>', s_tab_complete, { expr = true })
-- Accept completion
vim.keymap.set('i', '<CR>', cr_complete, { expr = true })
