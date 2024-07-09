local M = {}

local finders = require "telescope.finders"

local config = require("clang_reloader.config").opts
local util = require("clang_reloader.util")

--- Finder supplied to the telescope plugin as a custom picker.
---@return table Table of directories to be used as a prompt.
function M.finder()
	config = require("clang_reloader.config").opts
	require('clang_reloader.finder')
	local client = util.get_client()
	local current_src_dir = {}

	if not client or not client.config or not client.config.init_options then
		vim.api.nvim_err_writeln("No clangd client found.")
	else
		current_src_dir = { client.config.init_options.compilationDatabasePath }
	end

	if config.shorten_paths then
		current_src_dir[1] = util.shorten_path(current_src_dir[1])
	end

	current_src_dir = util.merge_tables(current_src_dir, util.find_build_dirs(vim.fn.getcwd(), config))

	return finders.new_table {
		results = util.merge_tables(current_src_dir, {unpack(util.shorten_paths(config.directories)), config.custom_prompt})
	}
end

return M
