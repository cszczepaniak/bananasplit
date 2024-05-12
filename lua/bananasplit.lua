local M = {}

function M.init()
	require("nvim-treesitter").define_modules({
		bananasplit = {
			module_path = "bananasplit.split",
			is_supported = function(lang)
				-- TODO support more langs?
				return lang == "go"
			end,
			keymaps = {
				split = "<leader>fc",
			},
		},
	})
end

return M
