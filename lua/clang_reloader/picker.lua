local pickers = require "telescope.pickers"
local conf = require "telescope.config".values

local telescope_reload_mapping = require("clang_reloader.mappings")
local telecsope_reload_finder = require("clang_reloader.finder")
local telescope = require("telescope")

local M = {}

--- Telescope picker changing the compilationDatabasePath where compile_commands.json is located.
function M.reload()
	local opts = require('telescope.themes').get_dropdown{
		winblend = 10,
		layout_config = {
			width = 0.6,
		},
	}

	pickers.new(opts, {
		prompt_title = "compilationDatabasePath",
		finder = telecsope_reload_finder.finder(),
		sorter = conf.generic_sorter(opts),
		attach_mappings = telescope_reload_mapping.attach_mappings,
	}):find()
end

return M

