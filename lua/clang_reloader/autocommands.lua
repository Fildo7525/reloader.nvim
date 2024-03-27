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

--- Check if a directory exists in this path
---@param path string The path to check.
---@return boolean Returns true if the directory exists, false otherwise.
local function isdir(path)
	-- "/" works on both Unix and Windows
	return exists(path.."/")
end

local id = vim.api.nvim_create_augroup("reloader.nvim", {
	clear = true,
})

if config.opts.detect_on_startup then
	vim.api.nvim_create_autocmd({ "LspAttach" }, {
		callback = function()
			local clients = vim.lsp.get_clients({name= "clangd"})
			if #clients ~= 1 then
				return;
			end

			local path = clients[1].config.init_options.compilationDatabasePath

			if not isdir(path) then
				require('clang_reloader.picker').reload()
			end
		end,
		group = id,
	})
end
