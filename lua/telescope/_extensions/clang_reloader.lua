local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
	error("This extension requires 'telescope.nvim'. (https://github.com/nvim-telescope/telescope.nvim)")
	return
end

local telescope_lsp_reloader = require("clang_reloader").picker
local telescope_lsp_config = require("clang_reloader").setup

return telescope.register_extension {
	setup = telescope_lsp_config,
	exports = {
		clang_reloader = telescope_lsp_reloader,
	}
}
