local M = {
	setup = require('clang_reloader.config').setup,
	picker = require('clang_reloader.picker').reload,
	config = require('clang_reloader.config').opts,
}

-- Setup autocommands
if vim.bo.filetype == "cpp" then
	require("clang_reloader.autocommands")
end

return M
