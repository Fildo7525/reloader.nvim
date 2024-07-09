local util = require("clang_reloader.util")

local M = {}

function M.finder(conf)
	local client = util.get_client()
	local current_src_dir = {}

	if not client or not client.config or not client.config.init_options then
		vim.api.nvim_err_writeln("No clangd client found.")
	else
		current_src_dir = { client.config.init_options.compilationDatabasePath }
	end

	if conf.shorten_paths then
		current_src_dir[1] = util.shorten_path(current_src_dir[1])
	end

	current_src_dir = util.merge_tables(current_src_dir, util.find_build_dirs(vim.fn.getcwd(), conf))

	return { util.merge_tables(current_src_dir, {unpack(util.shorten_paths(conf.directories)), conf.custom_prompt}) }
end

return M
