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

	-- Used to find the root_dir of the per-working-directory clangd client.
	-- Searched upwards from the file, a nested table means equal priority.
	-- Falls back to the working directory of the buffer.
	root_markers = { { "build" }, ".git" },

	-- Buffers do not inherit the buffer-local directory (:bcd), so a new file in the
	-- directory of a per-directory client would stay on the shared "clangd" client.
	-- When true, a file below the working directory of a "clangd_<wd>" client is given to
	-- that client (the deepest one wins), also when the reload is done.
	attach_by_path = true,

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
