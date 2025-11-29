local M = {}

--- Parses the inputed directory for build directories.
---@param directory string|nil Directory to be parsed
---@return table Table of directories located in the directory
function M.find_build_dirs(directory, config)
	local i, t, popen = 0, {}, io.popen

	local max_depth = ""
	if config.max_depth >= 0 then
		max_depth = "--max-depth " .. tostring(config.max_depth)
	end

	local pfile = popen("fd -I -t=f " .. max_depth .. "  'compile_commands.json' " .. directory)
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

local function find_query_driver_arg(cmd)
	for idx, arg in ipairs(cmd) do
		local match = string.match(arg, "--query[-]driver%S+")
		if match ~= nil then
			return idx
		end
	end
	return nil
end

function M.terminate_detached_clients()
	local clients = M.get_clients()
	for _, client in ipairs(clients) do
		if #client.attached_buffers == 0 then
			client:stop()
		end
	end
end


function M.handle_direct_choise(selection)
	local lspconfig = vim.lsp.config
	local clangConfig = lspconfig['clangd'] and vim.deepcopy(lspconfig['clangd']) or {}

	if vim.tbl_isempty(clangConfig) then
		vim.notify("Clangd LSP configuration not found in vim.lsp.config", vim.log.levels.ERROR)
		return
	end

	-- Setup the compilation database path
	selection = selection:gsub("%.%.%.", vim.fn.getcwd())
	clangConfig.init_options = {compilationDatabasePath = selection}

	-- Remove any existing query driver argument
	local idx = find_query_driver_arg(clangConfig.cmd)
	if idx ~= nil then
		table.remove(clangConfig.cmd, idx)
	end

	-- Setup the query drivers
	if selection:sub(#selection) == "/" then
		selection = selection:sub(1, #selection - 1)
	end

	if not vim.fn.filereadable(selection .. "/compile_commands.json") then
		vim.notify("The compile_commands.json file was found.", vim.log.levels.INFO)
		return
	end

	local file = selection .. "/compile_commands.json"

	if vim.fn.filereadable(file) == 0 then
		vim.notify("The compilation database file does not exist: " .. file, vim.log.levels.ERROR)
		return nil
	end

	local mappings = require("clang_reloader.mappings")
	local drivers = mappings.get_query_drivers(file)
	if drivers then
		table.insert(clangConfig.cmd, drivers)
	end

	-- Update the configuration with the user configuration
	vim.lsp.config("clangd", clangConfig)

	for _, client in ipairs(M.get_clients()) do
		client:stop()
	end

	vim.lsp.start(vim.lsp.config["clangd"])
end


--- This encapsulates the current client api from nvim.
--- @return table The current client.
function M.get_clients()
	return vim.lsp.get_clients({name="clangd"})
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
