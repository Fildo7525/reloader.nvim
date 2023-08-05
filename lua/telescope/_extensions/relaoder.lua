local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
	vim.notify("This plugin requires telescope.nvim", vim.log.levels.ERROR)
end

local telescope_lsp_reloader = require("telescope._extensions.reloader.picker")
local telescope_lsp_setup = require("telescope._extensions.reloader.setup")

return telescope.register_extension({
	setup = telescope_lsp_setup.setup,
	exports = {
		reload = telescope_lsp_reloader.reload,
	}

})
