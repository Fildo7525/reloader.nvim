local M = {
	setup = require('clang_reloader.config').setup,
	picker = require('clang_reloader.picker').reload,
	config = require('clang_reloader.config').opts,
}

-- Setup autocommands
require("clang_reloader.autocommands")

return M
