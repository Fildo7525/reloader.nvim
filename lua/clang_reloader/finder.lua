local M = {}

local finders = require "telescope.finders"

local config = require("clang_reloader.config").opts

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

function M.finder()
	local client = vim.lsp.get_clients({name="clangd"})[1]
	local current_src_dir = {}

	if not client or not client.config or not client.config.init_options then
		vim.api.nvim_err_writeln("No clangd client found.")
	else
		current_src_dir = { vim.lsp.get_clients({name="clangd"})[1].config.init_options.compilationDatabasePath }
	end

	if config.shorten_paths then
		current_src_dir[1] = current_src_dir[1]:gsub(vim.fn.getcwd(), "...")
	end

	current_src_dir = merge_tables(current_src_dir, find_build_dirs(vim.fn.getcwd()))
	current_src_dir = merge_tables(current_src_dir, config.directories)

	return finders.new_table {
		results = merge_tables(current_src_dir, {config.custom_prompt})
	}
end

return M
