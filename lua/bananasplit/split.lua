local api = vim.api
local ts = vim.treesitter
local ts_utils = require("nvim-treesitter.ts_utils")
local M = {}

local argwrap_fallback = false
local auto_format = false

---@param node TSNode
---@return TSNode[] list of children
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

---@class Range
---@field startLine number
---@field startChar number
---@field endLine number
---@field endChar number

---@param n TSNode
---@return Range
local function to_range(n)
	local start_line, start_col, end_line, end_col = ts.get_node_range(n)
	return {
		startLine = start_line,
		startChar = start_col,
		endLine = end_line,
		endChar = end_col,
	}
end

---@class Splittable
---@field startDelim string
---@field endDelim string
---@field nodes TSNode[]
---@field range Range

---@param node TSNode
---@return Splittable|nil
local function find_splittable(node)
	local n = find_ancestor_of_type(node, "argument_list")
	if n then
		-- For argument lists, children are the arguments which need to be put on new lines.
		return {
			startDelim = "(",
			endDelim = ")",
			nodes = named_children(n),
			range = to_range(n),
		}
	end

	n = find_ancestor_of_type(node, "composite_literal")
	if n then
		-- For composite literals, the first child is the type expression of the literal,
		-- and the second child is the body whose children are the nodes we need to put on
		-- new lines.
		local body = n:named_child(1)
		return {
			startDelim = "{",
			endDelim = "}",
			nodes = named_children(body),
			range = to_range(body),
		}
	end

	n = find_ancestor_of_type(node, "parameter_list")
	if n then
		-- For parameter lists, the children are what we want to put on new lines.
		return {
			startDelim = "(",
			endDelim = ")",
			nodes = named_children(n),
			range = to_range(n),
		}
	end

	return nil
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

	local txt_replacement = { splittable.startDelim }

	for _, n in ipairs(splittable.nodes) do
		-- The neovim API for editing text rejects anything with newlines. Split each
		-- argument into newlines and append each separately. We'll add a comma to the last
		-- one.
		for token in string.gmatch(ts.get_node_text(n, 0), "[^\n]+") do
			txt_replacement[#txt_replacement + 1] = token
		end
		txt_replacement[#txt_replacement] = txt_replacement[#txt_replacement] .. ","
	end

	txt_replacement[#txt_replacement + 1] = splittable.endDelim

	vim.api.nvim_buf_set_text(
		0,
		splittable.range.startLine,
		splittable.range.startChar,
		splittable.range.endLine,
		splittable.range.endChar,
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
