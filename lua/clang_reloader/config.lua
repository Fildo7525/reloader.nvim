local M = {
	_config = {},

	directories = {
		vim.fn.getcwd() .. "/.build",
	},

	autocommand = {
		enable = false,
		forbidden_dirs = { },
	},

	max_depth = -1,

	shorten_paths = false,

	custom_prompt = "+ Supply custom path",

	valid_compilers = {
		"clang",
		"clang++",
		"gcc",
		"g++",
		"nvcc",
	},
}

function M:instance(config)
	config = config or {}

	if vim.tbl_isempty(config) and not vim.tbl_isempty(self._config) then
		return self._config
	end

	self._config = vim.tbl_deep_extend('force', {}, self, config)
	return self._config
end

return M
