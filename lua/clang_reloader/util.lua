local M = {}

--- Parses the inputed directory for build directories.
---@param directory string|nil Directory to be parsed
---@return table Table of directories located in the directory
function M.find_build_dirs(directory, config)
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

function M.handle_direct_choise(selection, config)
	local clangConfig = config.config;
	local lspconfig = require "lspconfig"

	-- Setup the compilation database path
	selection = selection:gsub("%.%.%.", vim.fn.getcwd())
	clangConfig.init_options = {compilationDatabasePath = selection}

	if string.match(clangConfig.cmd[#clangConfig.cmd], "--query[-]driver%S+") ~= nil then
		table.remove(clangConfig.cmd, #clangConfig.cmd)
	end

	-- Setup the query drivers
	if selection:sub(#selection) == "/" then
		selection = selection:sub(1, #selection - 1)
	end

	if vim.fn.filereadable(selection .. "/compile_commands.json") then
		vim.notify("The compile_commands.json file was found.", vim.log.levels.INFO)
		return
	end

	local drivers = M.get_query_drivers(selection.."/compile_commands.json")
	if drivers then
		table.insert(clangConfig.cmd, drivers)
	end

	-- Update the configuration with the user configuration
	clangConfig = vim.tbl_deep_extend("force", clangConfig, config.options)
	lspconfig['clangd'].setup(clangConfig)

	vim.lsp.start_client(lspconfig['clangd'])

	-- Terminate all clients that have no buffers attached to it.
	M.timer = vim.fn.timer_start(500, M.terminate_detached_clients, {repeats = 1})
end


--- This encapsulates the current client api from nvim.
--- @return table The current client.
function M.get_clients()
	if vim.version().minor == 11 then
		return vim.lsp.get_clients({name="clangd"})
	else
		return vim.lsp.get_active_clients({name="clangd"})
	end
end

--- This encapsulates the current client api from nvim.
--- @return table The current client.
function M.get_client()
	return M.get_clients()[1]
end

function M.shorten_path(path)
	return path:gsub(vim.fn.getcwd() .. "/", ".../")
end

function M.shorten_paths(paths)
	for i, v in ipairs(paths) do
		paths[i] = M.shorten_path(v)
	end
	return paths
end

--- Merges two tables together. Copies from the second table are ignored.
---@param lhs table The first table to be merged.
---@param rhs table The second table to be merged, the copies of the already existing values will be ignored.
---@return table Returns a new table with the merged values.
function M.merge_tables(lhs, rhs)
	local copy = lhs
	for _, value in ipairs(rhs) do
		if not vim.tbl_contains(copy, value) then
			table.insert(copy, value)
		end
	end
	return copy
end

return M
