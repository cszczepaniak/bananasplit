local api = vim.api
local ts = vim.treesitter
local ts_utils = require("nvim-treesitter.ts_utils")
local M = {}

local argwrap_fallback = false

---@param child TSNode
local function find_arg_list_at_cursor(child)
	if not child then
		return nil
	end

	local type = child:type()
	if type == "argument_list" then
		return child
	else
		return find_arg_list_at_cursor(child:parent())
	end
end

---@param node TSNode
function M.split(node)
	local the_node = node or ts.get_node()
	local args = find_arg_list_at_cursor(the_node)
	if not args then
		if argwrap_fallback then
			-- If we can't find a suitable target for splitting, we'll fall back to ArgWrap if it's
			-- configured.
			vim.cmd(":ArgWrap")
		end
		return
	end

	local txt_replacement = { "(" }

	for arg, _ in args:iter_children() do
		if arg:named() then
			-- The neovim API for editing text rejects anything with newlines. Split each
			-- argument into newlines and append each separately. We'll add a comma to the last
			-- one.
			for token in string.gmatch(ts.get_node_text(arg, 0), "[^\n]+") do
				txt_replacement[#txt_replacement + 1] = token
			end
			txt_replacement[#txt_replacement] = txt_replacement[#txt_replacement] .. ","
		end
	end

	txt_replacement[#txt_replacement + 1] = ")"

	local rng = ts_utils.node_to_lsp_range(args)
	vim.api.nvim_buf_set_text(
		0,
		rng.start.line,
		rng.start.character,
		rng["end"].line,
		rng["end"].character,
		txt_replacement
	)

	require("conform").format()
end

function M.attach(bufnr)
	local buf = bufnr or api.nvim_get_current_buf()

	local config = require("nvim-treesitter.configs").get_module("bananasplit")
	argwrap_fallback = config.argwrap_fallback or false

	for funcname, mapping in pairs(config.keymaps) do
		api.nvim_buf_set_keymap(
			buf,
			"n",
			mapping,
			string.format(":lua require'bananasplit.split'.%s()<CR>", funcname),
			{ silent = true, desc = string.format("bananasplit: %s", funcname) }
		)
	end
end

function M.detach(bufnr)
	local buf = bufnr or api.nvim_get_current_buf()

	local config = require("nvim-treesitter.configs").get_module("bananasplit")
	for _, mapping in pairs(config.keymaps) do
		api.nvim_buf_del_keymap(buf, "n", mapping)
	end
end

return M
