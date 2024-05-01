local M = {}

M.opts = {
	config = require("usr.lsp.settings.clangd"),
	max_depth = -1,
	shorten_paths = false,
	directories = {
		vim.fn.getcwd(),
	},
	detect_on_startup = true,
	enable_autocommands = true,
	options = {
		on_attach = require("usr.lsp.handlers").on_attach,
		capabilities = require("usr.lsp.handlers").capabilities,
	},
}

function M.setup(options)
	options = options or {}
	if options.directories and #options.directories > 0 then
		M.opts.directories = options.directories
	end

	M.opts.options = options.options or M.opts.options
end

return M
