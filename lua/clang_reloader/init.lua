local conf = require('clang_reloader.config')
local util = require('clang_reloader.util')

local M = {}

function M.setup(user_config)
	user_config = conf:instance(user_config)

	if user_config.detect_on_startup then
		require('clang_reloader.autocommands')
	end
end

local function handle_selection(selected)
	local config = conf:instance()
	if not selected then
		return
	end

	if selected == config.custom_prompt then
		selected = vim.fn.input("Enter the path to the compilation database directory: ", vim.fn.getcwd(), "file")
		vim.notify(selected, vim.log.levels.INFO)
		if selected == "" or vim.fn.filereadable(selected .. "compile_commands.json") then
			return
		end
	end

	util.handle_direct_choise(selected)
end

local function simple_finder()
	local client = util.get_client()
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
	local prompt = "compilationDatabasePath"
	local paths = unpack(simple_finder());

	vim.ui.select(
		paths,
		{ prompt = prompt },
		handle_selection
	)
end

return M
