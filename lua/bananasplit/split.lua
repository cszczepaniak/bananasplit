local api = vim.api
local ts = vim.treesitter
local ts_utils = require("nvim-treesitter.ts_utils")
local M = {}

local argwrap_fallback = false
local auto_format = false

---@param node TSNode
---@return table TSNode list of children
local function named_children(node)
	local l = {}
	for child in node:iter_children() do
		if child:named() then
			l[#l + 1] = child
		end
	end
	return l
end

---@param child TSNode
---@param type string
local function find_ancestor_of_type(child, type)
	if not child then
		return nil
	end

	if child:type() == type then
		return child
	else
		return find_ancestor_of_type(child:parent(), type)
	end
end

---@param node TSNode
local function find_splittable(node)
	local n = find_ancestor_of_type(node, "call_expression")
	if n then
		-- For call expressions, the first child is the type expression of the call, and the
		-- second child is the arguemtn list whose children are the nodes we need to put on
		-- new lines.
		local args = n:named_child(1)
		return {
			start = "(",
			["end"] = ")",
			nodes = named_children(args),
			range = ts_utils.node_to_lsp_range(args),
		}
	end

	n = find_ancestor_of_type(node, "composite_literal")
	if n then
		-- For composite literals, the first child is the type expression of the literal,
		-- and the second child is the body whose children are the nodes we need to put on
		-- new lines.
		local body = n:named_child(1)
		return {
			start = "{",
			["end"] = "}",
			nodes = named_children(body),
			range = ts_utils.node_to_lsp_range(body),
		}
	end

	n = find_ancestor_of_type(node, "parameter_list")
	if n then
		-- For parameter lists, the children are what we want to put on new lines.
		return {
			start = "(",
			["end"] = ")",
			nodes = named_children(n),
			range = ts_utils.node_to_lsp_range(n),
		}
	end

	return nil
end

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
	local splittable = find_splittable(the_node)
	if not splittable then
		if argwrap_fallback then
			vim.cmd(":ArgWrap")
		end
		return
	end

	local txt_replacement = { splittable.start }

	for _, n in ipairs(splittable.nodes) do
		-- The neovim API for editing text rejects anything with newlines. Split each
		-- argument into newlines and append each separately. We'll add a comma to the last
		-- one.
		for token in string.gmatch(ts.get_node_text(n, 0), "[^\n]+") do
			txt_replacement[#txt_replacement + 1] = token
		end
		txt_replacement[#txt_replacement] = txt_replacement[#txt_replacement] .. ","
	end

	txt_replacement[#txt_replacement + 1] = splittable["end"]

	vim.api.nvim_buf_set_text(
		0,
		splittable.range.start.line,
		splittable.range.start.character,
		splittable.range["end"].line,
		splittable.range["end"].character,
		txt_replacement
	)

	if auto_format then
		require("conform").format()
	end
end

function M.attach(bufnr)
	local buf = bufnr or api.nvim_get_current_buf()

	local config = require("nvim-treesitter.configs").get_module("bananasplit")
	argwrap_fallback = config.argwrap_fallback or false
	auto_format = config.auto_format or false

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
