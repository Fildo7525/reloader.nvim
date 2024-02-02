local M = {}

M.opts = {
	directories = {
		vim.fn.getcwd(),
	},
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
