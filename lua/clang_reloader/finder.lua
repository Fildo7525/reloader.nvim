local M = {}

local finders = require "telescope.finders"

local telescop_reload_config = require("clang_reloader.config").opts

local function merge_tables(lhs, rhs)
	local copy = lhs
	for _, value in ipairs(rhs) do
		if not vim.tbl_contains(copy, value) then
			table.insert(copy, value)
		end
	end
	return copy
end

--- Parses the inputed directory for build directories.
---@param directory string Directory to be parsed
---@return table Table of directories located in the directory
local function find_build_dirs(directory)
	local i, t, popen = 0, {}, io.popen

	local pfile = popen('find . -maxdepth 2 -name "compile_commands.json" -type f')
	if pfile == nil then
		return t
	end

	for filename in pfile:lines() do
		i = i + 1
		t[i] = filename:gsub("./", "")
		t[i] = filename:gsub("/compile_commands.json", "")
	end
	pfile:close()

	return t
end

function M.finder()
	local current_src_dir = { vim.lsp.get_active_clients({name="clangd"})[1].config.init_options.compilationDatabasePath }
	current_src_dir = merge_tables(current_src_dir, find_build_dirs("."))

	return finders.new_table {
		results = merge_tables(current_src_dir, telescop_reload_config.directories),
	}
end

return M
