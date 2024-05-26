local M = {}

local finders = require "telescope.finders"

local config = require("clang_reloader.config").opts
local util = require("clang_reloader.util")

--- Parses the inputed directory for build directories.
---@param directory string|nil Directory to be parsed
---@return table Table of directories located in the directory
local function find_build_dirs(directory)
	local i, t, popen = 0, {}, io.popen

	local max_depth = ""
	if config.max_depth >= 0 then
		max_depth = "-maxdepth " .. tostring(config.max_depth)
	end

	local pfile = popen("find " .. directory .. " " .. max_depth .. "  -name 'compile_commands.json' -type f")
	if pfile == nil then
		return t
	end

	for filename in pfile:lines() do
		if config.shorten_paths then
			filename = filename:gsub(directory, "")
		end

		if #filename ~= 0 then
			i = i + 1
			t[i] = filename:gsub("/compile_commands.json", "")

			if config.shorten_paths then
				t[i] = t[i]:gsub("^/", ".../")
			end
		end
	end
	pfile:close()

	return t
end

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

	current_src_dir = util.merge_tables(current_src_dir, find_build_dirs(vim.fn.getcwd()))

	return finders.new_table {
		results = util.merge_tables(current_src_dir, {unpack(util.shorten_paths(config.directories)), config.custom_prompt})
	}
end

return M
