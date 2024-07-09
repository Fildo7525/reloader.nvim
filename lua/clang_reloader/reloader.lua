local M = {}

local conf = require('clang_reloader.config').opts
local finder = require('clang_reloader.no_telescope.finder').finder
local util = require('clang_reloader.util')

function M.reload(config)
	config = config or {}
	config = vim.tbl_deep_extend("force", conf, config)

	if not config.use_telescope then
		local prompt = "compilationDatabasePath"
		local paths = unpack(finder(config));
		vim.ui.select(paths, {
			prompt = prompt,
			},
			function(selected)
				if selected == config.custom_prompt then
					selected = vim.fn.input("Enter the path to the compilation database directory: ", vim.fn.getcwd(), "file")
					vim.notify(selected, vim.log.levels.INFO)
					if selected == "" or vim.fn.filereadable(selected .. "compile_commands.json") then
						return
					end
				end

				util.handle_direct_choise(selected, config)
			end)
	end

end

return M
