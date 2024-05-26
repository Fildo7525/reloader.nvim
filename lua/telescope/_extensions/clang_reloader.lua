local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
	error("This extension requires 'telescope.nvim'. (https://github.com/nvim-telescope/telescope.nvim)")
	return
end

return telescope.register_extension {
	setup = require("clang_reloader").setup,
	exports = {
		clang_reloader = require("clang_reloader").picker,
	}
}
