local M = {}

--- This encapsulates the current client api from nvim.
--- @return table The current client.
function M.get_clients()
	if vim.version().minor == 11 then
		return vim.lsp.get_clients({name="clangd"})
	else
		return vim.lsp.get_active_clients({name="clangd"})
	end
end

--- This encapsulates the current client api from nvim.
--- @return table The current client.
function M.get_client()
	return M.get_clients()[1]
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
