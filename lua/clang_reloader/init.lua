local conf = require('clang_reloader.config').opts

local M = {
	setup = require('clang_reloader.config').setup,
	picker = require('clang_reloader.picker').reload,
	config = conf.opts,
}

-- Setup autocommands
if conf.enable_autocommands then
	require("clang_reloader.autocommands")
end

return M
