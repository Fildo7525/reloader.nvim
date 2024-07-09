local M = {}

M.opts = {
	use_telescope = true,
	forbidden_dirs = {

	},
	config = require("usr.lsp.settings.clangd"),

	directories = {
		vim.fn.getcwd() .. "/.build",
	},

	detect_on_startup = true,

	max_depth = -1,

	shorten_paths = false,

	options = {
		on_attach = require("usr.lsp.handlers").on_attach,
		capabilities = require("usr.lsp.handlers").capabilities,
	},

	custom_prompt = "+ Supply custom path",

	valid_compilers = {
		"clang",
		"clang++",
		"gcc",
		"g++",
		"nvcc",
	},
}

function M.setup(options)
	options = options or {}

	M.opts = vim.tbl_deep_extend("force", M.opts, options)
end

return M
