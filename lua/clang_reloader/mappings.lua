local M = {}
M.timer = nil

local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local lspconfig = require "lspconfig"

local config = require("clang_reloader.config")

local function table_size(table)
	local size = 0

	for _ in pairs(table) do
		size = size + 1
	end

	return size
end

--- Terminates all clients that have no buffers attached to it.
function M.terminate_detached_clients()
	local clients = vim.lsp.get_clients()

	for _, value in ipairs(clients) do
		if table_size(value.attached_buffers) == 0 then
			value.stop()
			value.rpc.terminate()
		end
	end

	M.timer = nil
end

--- Parses the inputed compile commands file for the query drivers.
---@param file string The file to be parsed.
---@return string|nil The query drivers to be added to clangd configuration.
function M.get_query_drivers(file)
	local prefix = "--query-driver="
	local drivers = {}

	local pfile = io.popen("jq -r '.[].command | split(\" \") | .[0]' " .. file .." | sort | uniq")
	if pfile == nil then
		return ""
	end

	for compiler in pfile:lines() do
		if compiler:len() ~= 0 and not (compiler == "/usr/bin/c++" or compiler == "/usr/bin/gcc") then
			table.insert(drivers, compiler)
		end
	end
	pfile:close()

	if #drivers == 0 then
		return nil
	end

	return prefix .. table.concat(drivers, ",")
end

function M.attach_mappings(prompt_bufnr)
	actions.select_default:replace(function()
		actions.close(prompt_bufnr)
		local selection = action_state.get_selected_entry()
		local client = vim.lsp.get_clients({name = "clangd"})
		if #client == 0 then
			vim.notify("The clangd server is not running.", vim.log.levels.ERROR)
			return
		end

		local clangConfig = config.opts.config;

		-- Setup the compilation database path
		selection[1] = selection[1]:gsub("%.%.%.", vim.fn.getcwd())
		clangConfig.init_options = {compilationDatabasePath = selection[1]}

		-- Setup the query drivers
		local drivers = M.get_query_drivers(selection[1].."/compile_commands.json")
		if drivers then
			table.insert(clangConfig.cmd, drivers)
		end

		-- Update the configuration with the user configuration
		clangConfig = vim.tbl_deep_extend("force", clangConfig, config.opts.options)
		lspconfig['clangd'].setup(clangConfig)

		vim.lsp.start_client(lspconfig['clangd'])

		-- Terminate all clients that have no buffers attached to it.
		M.timer = vim.fn.timer_start(500, M.terminate_detached_clients, {repeats = 1})
	end)
	return true
end

return M
