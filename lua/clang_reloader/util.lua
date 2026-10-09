local M = {}

local BASE_NAME = "clangd"

--- Parses the inputed directory for build directories.
---@param directory string|nil Directory to be parsed
---@return table Table of directories located in the directory
function M.find_build_dirs(directory, config)
	local i, t, popen = 0, {}, io.popen

	local max_depth = ""
	if config.max_depth >= 0 then
		max_depth = "--max-depth " .. tostring(config.max_depth)
	end

	local pfile = popen("fd -I -t=f " .. max_depth .. "  'compile_commands.json' " .. directory)
	if pfile == nil then
		return t
	end

	for filename in pfile:lines() do
		if config.shorten_paths then
			filename = filename:gsub(directory, "")
		end

		if #filename ~= 0 then
			i = i + 1
			t[i] = filename:gsub("/compile_commands.json", "")

			if config.shorten_paths then
				t[i] = t[i]:gsub("^/", ".../")
			end
		end
	end
	pfile:close()

	return t
end

local function find_query_driver_arg(cmd)
	for idx, arg in ipairs(cmd) do
		local match = string.match(arg, "--query[-]driver%S+")
		if match ~= nil then
			return idx
		end
	end
	return nil
end

function M.terminate_detached_clients()
	local clients = M.get_clients()
	for _, client in ipairs(clients) do
		if #client.attached_buffers == 0 then
			client:stop()
		end
	end
end


local function normalize(path)
	local p = vim.fs.normalize(path):gsub("/+$", "")
	return p == "" and "/" or p
end

--- Working directory of a buffer.
--- The reloaded buffer uses the supplied cwd (it is the current one when the picker was
--- opened). Other buffers use their :bcd directory, falling back to the global directory.
local function buf_wd(buf, bufnr, cwd)
	if buf == bufnr then
		return cwd
	end
	if vim.fn.haslocaldir(-1, -1, buf) ~= 0 then
		return normalize(vim.fn.getcwd(-1, -1, buf))
	end
	return normalize(vim.fn.getcwd(-1, -1))
end

--- Name of the clangd client that belongs to a working directory.
local function client_name(wd)
	return BASE_NAME .. "_" .. (wd:gsub("[^%w]", "_"))
end

--- Working directory of a buffer that is not being reloaded.
local function buffer_wd(buf)
	if vim.fn.haslocaldir(-1, -1, buf) ~= 0 then
		return normalize(vim.fn.getcwd(-1, -1, buf))
	end
	if buf == vim.api.nvim_get_current_buf() then
		return normalize(vim.fn.getcwd())
	end
	return normalize(vim.fn.getcwd(-1, -1))
end

local guard_installed = false

--- vim.lsp.enable() attaches the shared "clangd" client to every C/C++ buffer on FileType,
--- also to buffers that are already served by a "clangd_<wd>" client (:edit, a file that is
--- opened later in the same directory). Such a buffer would have two clangd clients, so the
--- shared one is swapped for the per-directory client as soon as it attaches.
--- Installed on the first reload, per-directory clients do not exist before.
local function ensure_guard()
	if guard_installed then
		return
	end
	guard_installed = true

	vim.api.nvim_create_autocmd("LspAttach", {
		group = vim.api.nvim_create_augroup("reloader.nvim.per_wd", { clear = true }),
		callback = function(args)
			local client = vim.lsp.get_client_by_id(args.data.client_id)
			if not client or client.name ~= BASE_NAME then
				return
			end

			local buf = args.buf

			-- A replaced client may still be shutting down, only a running one can take over
			local target
			for _, candidate in ipairs(vim.lsp.get_clients({ name = client_name(buffer_wd(buf)) })) do
				if not candidate:is_stopped() then
					target = candidate
					break
				end
			end
			if not target then
				return
			end

			vim.schedule(function()
				if not vim.api.nvim_buf_is_valid(buf) then
					return
				end

				vim.lsp.buf_detach_client(buf, client.id)
				vim.lsp.buf_attach_client(buf, target.id)

				local remaining = 0
				for b in pairs(client.attached_buffers) do
					if b ~= buf and vim.api.nvim_buf_is_valid(b) then
						remaining = remaining + 1
					end
				end
				if remaining == 0 and not client:is_stopped() then
					client:stop()
				end
			end)
		end,
	})
end

--- Gives the working directory of a buffer its own clangd client "clangd_<wd>" that uses
--- the selected compilation database:
---  1. every buffer with the same working directory is detached from the other clangd
---     clients (a previous "clangd_<wd>" is replaced),
---  2. clangd clients that end up without buffers are stopped,
---  3. the new client is started and the buffers are attached to it.
--- Buffers of other working directories keep their clients.
---@param selection string Directory containing compile_commands.json ("..." stands for cwd).
---@param bufnr? integer Buffer that is reloaded. Defaults to the current buffer.
---@param cwd? string Working directory of that buffer. Defaults to the current cwd.
function M.handle_direct_choise(selection, bufnr, cwd)
	if bufnr == nil or bufnr == 0 then
		bufnr = vim.api.nvim_get_current_buf()
	end
	cwd = normalize(cwd or vim.fn.getcwd())

	-- Expand the shortened path and drop the trailing slash
	selection = selection:gsub("^%.%.%.", function() return cwd end)
	selection = selection:gsub("/+$", "")

	local file = selection .. "/compile_commands.json"
	if vim.fn.filereadable(file) == 0 then
		vim.notify("The compilation database file does not exist: " .. file, vim.log.levels.ERROR)
		return
	end

	-- Private copy of the base configuration, the registered one is never modified
	local base = vim.lsp.config[BASE_NAME]
	if not base or not base.cmd then
		vim.notify("'" .. BASE_NAME .. "' LSP configuration not found in vim.lsp.config", vim.log.levels.ERROR)
		return
	end
	local cfg = vim.deepcopy(base)

	local new_lsp_name = client_name(cwd)
	cfg.name = new_lsp_name
	cfg.root_markers = nil
	cfg.root_dir = vim.fs.root(bufnr, require("clang_reloader.config"):instance().root_markers) or cwd
	cfg.cmd_cwd = cwd
	cfg.init_options = vim.tbl_extend("force", cfg.init_options or {}, {
		compilationDatabasePath = selection,
	})

	-- Replace the query driver argument
	if type(cfg.cmd) == "table" then
		local idx = find_query_driver_arg(cfg.cmd)
		if idx ~= nil then
			table.remove(cfg.cmd, idx)
		end

		local drivers = require("clang_reloader.mappings").get_query_drivers(file)
		if drivers then
			table.insert(cfg.cmd, drivers)
		end
	end

	-- Collect the buffers of this working directory and the clients they are attached to.
	-- A previous client of this directory is replaced, so all of its buffers move.
	local to_attach = { [bufnr] = true }
	local moves = {}

	for _, client in ipairs(M.get_clients()) do
		local move, remaining = {}, 0
		for buf in pairs(client.attached_buffers) do
			if not vim.api.nvim_buf_is_valid(buf) then
				goto continue
			end

			if client.name == new_lsp_name or buf == bufnr or buf_wd(buf, bufnr, cwd) == cwd then
				table.insert(move, buf)
				to_attach[buf] = true
			else
				remaining = remaining + 1
			end

			::continue::
		end
		table.insert(moves, { client = client, move = move, remaining = remaining })
	end

	-- Start the new client first, so a failure leaves the old clients running.
	-- reuse_client is disabled, a replaced client has the same name and root_dir.
	local client_id = vim.lsp.start(cfg, {
		attach = false,
		reuse_client = function()
			return false
		end,
	})
	if client_id == nil then
		vim.notify("Failed to start clangd client " .. new_lsp_name, vim.log.levels.ERROR)
		return
	end

	ensure_guard()

	for _, m in ipairs(moves) do
		for _, buf in ipairs(m.move) do
			vim.lsp.buf_detach_client(buf, m.client.id)
		end
	end

	local count = 0
	for buf in pairs(to_attach) do
		if vim.api.nvim_buf_is_valid(buf) then
			vim.lsp.buf_attach_client(buf, client_id)
			count = count + 1
		end
	end

	-- Stop the clients that no longer serve any buffer
	for _, m in ipairs(moves) do
		if m.remaining == 0 and not m.client:is_stopped() then
			m.client:stop()
		end
	end

	vim.notify(("%s (root: %s): %d buffer%s attached"):format(new_lsp_name, cfg.root_dir, count, count == 1 and "" or "s"))
end


--- This encapsulates the current client api from nvim.
---@param bufnr? integer Only return clients attached to this buffer.
---@return vim.lsp.Client[] The clangd clients ("clangd" and "clangd_*").
function M.get_clients(bufnr)
	local filter = bufnr and { bufnr = bufnr } or {}
	return vim.tbl_filter(function(client)
		return client.name == BASE_NAME or vim.startswith(client.name, BASE_NAME .. "_")
	end, vim.lsp.get_clients(filter))
end

--- This encapsulates the current client api from nvim.
---@param bufnr? integer Only consider clients attached to this buffer.
---@return vim.lsp.Client|nil The first clangd client.
function M.get_client(bufnr)
	return M.get_clients(bufnr)[1]
end

function M.shorten_path(path)
	return path:gsub(vim.fn.getcwd() .. "/", ".../")
end

function M.shorten_paths(paths)
	for i, v in ipairs(paths) do
		paths[i] = M.shorten_path(v)
	end
	return paths
end

--- Merges two tables together. Copies from the second table are ignored.
---@param lhs table The first table to be merged.
---@param rhs table The second table to be merged, the copies of the already existing values will be ignored.
---@return table Returns a new table with the merged values.
function M.merge_tables(lhs, rhs)
	local copy = lhs
	for _, value in ipairs(rhs) do
		if not vim.tbl_contains(copy, value) then
			table.insert(copy, value)
		end
	end
	return copy
end

return M
