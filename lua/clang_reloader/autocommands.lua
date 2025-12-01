local config = require("clang_reloader.config")

--- Check if a file or directory exists in this path.
---@param file string The path to check.
---@return boolean Returns true if the file or directory exists, false otherwise.
local function exists(file)
	local ok, _, code = os.rename(file, file)
	if not ok then
		if code == 13 then
			-- Permission denied, but it exists
			return true
		end
	end
	return ok
end

local id = vim.api.nvim_create_augroup("reloader.nvim", {
	clear = true,
})

if config.autocommand.enable then
	vim.api.nvim_create_autocmd({ "LspAttach" }, {
		callback = function()
			local clients = require('clang_reloader.util').get_clients()

			if vim.tbl_contains(config.autocommand.forbidden_dirs, vim.fn.getcwd()) then
				return
			end

			if #clients ~= 1 then
				return;
			end

			local path = clients[1].config.init_options.compilationDatabasePath

			if not exists(path .. "/") then
				require('clang_reloader').reload()
			end
		end,
		group = id,
	})
end
