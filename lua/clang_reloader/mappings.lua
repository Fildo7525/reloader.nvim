local M = {}
M.timer = nil

local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local lspconfig = require "lspconfig"

local config = require("clang_reloader.config").opts
local util = require("clang_reloader.util")

local function table_size(table)
	local size = 0

	for _ in pairs(table) do
		size = size + 1
	end

	return size
end

--- Terminates all clients that have no buffers attached to it.
function M.terminate_detached_clients()
	local clients = util.get_clients()

	for _, value in ipairs(clients) do
		if table_size(value.attached_buffers) == 0 then
			value.stop()
			value.rpc.terminate()
		end
	end

	M.timer = nil
end

--- Check if a supplied argument is a cross compiler.
---@param arg string The argument to be checked.
---@return boolean True if the argument is a cross compiler, false otherwise.
function M.is_cross_compiler(arg)
	if arg:len() == 0 then
		return false
	end

	local compiler = arg:match("/([^/]+)$")
	if compiler == nil then
		return false
	end

	for _, valid_compiler in ipairs(config.valid_compilers) do
		if compiler:match(valid_compiler:gsub("%+", "%%+")) ~= nil and compiler ~= valid_compiler then
			return true
		end
	end

	return false
end

--- Parses the inputed compile commands file for the drivers.
---@param file string The file to be parsed.
---@return table|nil The drivers to be added to clangd configuration.
function M.drivers(file)
	local drivers = {}

	for num=0,3 do
		drivers = {}

		local pfile = io.popen("jq -r '.[].command | split(\" \") | .[" .. tostring(num) .. "]' " .. file .." | sort | uniq")
		if pfile == nil then
			return nil
		end

		for arg in pfile:lines() do
			if M.is_cross_compiler(arg) then
				table.insert(drivers, arg)
				num = -1
			end
		end
		pfile:close()

		if num == -1 then
			return drivers
		end

		num = num + 1
	end

	if #drivers == 0 then
		return nil
	end
end

--- Parses the inputed compile commands file for the query drivers.
---@param file string The file to be parsed.
---@return string|nil The query drivers to be added to clangd configuration.
function M.get_query_drivers(file)
	local prefix = "--query-driver="
	local drivers = M.drivers(file)

	if drivers == nil then
		return nil
	end

	return prefix .. table.concat(drivers, ",")
end

function M.handle_direct_choise(selection)
	local clangConfig = config.config;

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

function M.attach_mappings(prompt_bufnr)
	actions.select_default:replace(function()
		actions.close(prompt_bufnr)
		local selection = action_state.get_selected_entry()[1]
		local client = util.get_clients()
		if #client == 0 then
			vim.notify("The clangd server is not running.", vim.log.levels.ERROR)
			return
		end

		if selection:match(config.custom_prompt) == nil then
			M.handle_direct_choise(selection)
		else
			local ret = vim.fn.input("Enter the path to the compilation database: ", vim.fn.getcwd(), "file")
			M.handle_direct_choise(ret)
		end

	end)
	return true
end

return M
