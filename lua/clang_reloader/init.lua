local conf = require('clang_reloader.config').opts

local M = {
	setup = require('clang_reloader.config').setup,
	picker = require('clang_reloader.picker').reload,
}

-- Setup autocommands
if conf.detect_on_startup then
	require("clang_reloader.autocommands")
end

return M
