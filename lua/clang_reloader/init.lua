local conf = require('clang_reloader.config')
local util = require('clang_reloader.util')

local M = {}

function M.setup(user_config)
	user_config = conf:instance(user_config)

	if user_config.autocommand.enable then
		require('clang_reloader.autocommands')
	end
end

local function handle_selection(selected, bufnr, cwd)
	local config = conf:instance()
	if not selected then
		return
	end

	if selected == config.custom_prompt then
		selected = vim.fn.input("Enter the path to the compilation database directory: ", cwd, "file")
		if selected == "" then
			return
		end
	end

	util.handle_direct_choise(selected, bufnr, cwd)
end

local function simple_finder(bufnr)
	local client = util.get_client(bufnr)
	local current_src_dir = {}
	local config = conf:instance()

	if not client or not client.config or not client.config.init_options then
		vim.notify("No clangd client found.", vim.log.levels.WARN)
		return { util.merge_tables(util.find_build_dirs(vim.fn.getcwd(), config), { unpack(util.shorten_paths(config.directories)), config.custom_prompt })}
	else
		current_src_dir = { client.config.init_options.compilationDatabasePath }
	end

	if config.shorten_paths then
		current_src_dir[1] = util.shorten_path(current_src_dir[1])
	end

	current_src_dir = util.merge_tables(current_src_dir, util.find_build_dirs(vim.fn.getcwd(), config))

	return { util.merge_tables(current_src_dir, {unpack(util.shorten_paths(config.directories)), config.custom_prompt}) }
end

function M.reload()
	-- The buffer and its working directory are captured now: the picker is asynchronous
	-- and the selection must be applied to the buffer it was opened from.
	local bufnr = vim.api.nvim_get_current_buf()
	local cwd = vim.fn.getcwd()

	local prompt = "compilationDatabasePath"
	local paths = unpack(simple_finder(bufnr));

	vim.ui.select(
		paths,
		{ prompt = prompt },
		function(selected)
			handle_selection(selected, bufnr, cwd)
		end
	)
end

return M
