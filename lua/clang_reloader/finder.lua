local M = {}

local finders = require "telescope.finders"

local telescop_reload_config = require("clang_reloader.config").opts

--- Merges two tables together. Copyies from the second table are ignored.
---@param lhs table The first ttable to be merged.
---@param rhs table The second table to be merged, the copyies of the already existing values will be ignored.
---@return table Retruns a new table with the merged values.
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
---@param directory string|nil Directory to be parsed
---@return table Table of directories located in the directory
local function find_build_dirs(directory)
	local i, t, popen = 0, {}, io.popen

	local pfile = popen("find " .. directory .. " -maxdepth 2 -name 'compile_commands.json' -type f")
	if pfile == nil then
		return t
	end

	for filename in pfile:lines() do
		i = i + 1
		t[i] = filename:gsub("/compile_commands.json", "")
	end
	pfile:close()

	return t
end

function M.finder()
	local current_src_dir = { vim.lsp.get_active_clients({name="clangd"})[1].config.init_options.compilationDatabasePath }
	current_src_dir = merge_tables(current_src_dir, find_build_dirs(vim.fn.getcwd()))

	return finders.new_table {
		results = merge_tables(current_src_dir, telescop_reload_config.directories),
	}
end

return M
