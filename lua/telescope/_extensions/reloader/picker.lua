local pickers = require "telescope.pickers"
local conf = require "telescope.config" .values

local telescope_reload_mapping = require("telescope._extensions.reloader.mappings")
local telecsope_reload_finder = require("telescope._extensions.reloader.finder")

local M = {}

--- Telescope picker changing the compilationDatabasePath where compile_commands.json is located.
function M.reload()
	local opts = require('telescope.themes').get_dropdown{}

	pickers.new(opts, {
		prompt_title = "compilationDatabasePath",
		finder = telecsope_reload_finder.finder(),
		sorter = conf.generic_sorter(opts),
		attach_mappings = telescope_reload_mapping.attach_mappings,
	}):find()
end

return M

