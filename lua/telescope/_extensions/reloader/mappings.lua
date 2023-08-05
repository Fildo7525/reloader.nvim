local M = {}

local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local lspconfig = require "lspconfig"

local config = require("telescope._extentions.reloader.config")

local function table_size(table)
	local size = 0

	for _ in pairs(table) do
		size = size + 1
	end

	return size
end


--- Terminates all clients that have no buffers attached to it.
local function terminate_detached_clients()
	local clients = vim.lsp.get_active_clients()

	for _, value in ipairs(clients) do
		if table_size(value.attached_buffers) == 0 then
			value.rpc.terminate()
		end
	end
end

function M.attach_mappings(prompt_bufnr)
	actions.select_default:replace(function()
		actions.close(prompt_bufnr)
		local selection = action_state.get_selected_entry()
		local client = vim.lsp.get_active_clients({name = "clangd"})
		if #client == 0 then
			vim.notify("The clangd server is not running.", vim.log.levels.ERROR)
			return
		end

		vim.lsp.stop_client(client, true)

		local clangConfig = require("usr.lsp.settings.clangd");
		clangConfig.init_options = {compilationDatabasePath = selection[1]}
		clangConfig = vim.tbl_deep_extend("force", clangConfig, config.options)
		lspconfig['clangd'].setup(clangConfig)

		vim.lsp.start_client(lspconfig['clangd'])
		-- Does not work in here. However, when you call it separately, it works.
		terminate_detached_clients()
	end)
	return true
end

return M
