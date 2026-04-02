local M = {}

local ns = vim.api.nvim_create_namespace("jj-conflict")

M.ns = ns

local default_highlights = {
	ours = { fg = "#50fa7b", bg = "#282a36", bold = true },
	theirs = { fg = "#ffb86c", bg = "#282a36", bold = true },
	marker = { fg = "#f8f8f2", bg = "#6272a4", bold = true },
	label = { fg = "#8be9fd", italic = true },
	diff_remove = { fg = "#ff5555", bg = "#2d1f1f" },
	diff_add = { fg = "#50fa7b", bg = "#1f2f1f" },
}

function M.setup()
	for name, highlight in pairs(default_highlights) do
		local ok, hl =
			pcall(vim.api.nvim_get_hl, 0, { name = "JjConflict" .. name:gsub("^%l", string.upper), link = false })
		if not ok or not hl.fg then
			local hl_name = "JjConflict" .. name:gsub("^%l", string.upper)
			vim.api.nvim_set_hl(0, hl_name, highlight)
		end
	end
end

function M.highlight_conflict(bufnr, conflict, config)
	local start_line = conflict.start_line
	local end_line = conflict.end_line

	vim.api.nvim_buf_clear_namespace(bufnr, ns, start_line, end_line + 1)

	local marker_hl = "JjConflictMarker"
	local ours_hl = "JjConflictOurs"
	local theirs_hl = "JjConflictTheirs"
	local label_hl = "JjConflictLabel"
	local diff_rem_hl = "JjConflictDiffRemove"
	local diff_add_hl = "JjConflictDiffAdd"

	for i = start_line, end_line do
		local line = vim.api.nvim_buf_get_lines(bufnr, i, i + 1, false)[1] or ""

		if line:match("^<{7,}") or line:match("^>{7,}") then
			vim.api.nvim_buf_set_extmark(bufnr, ns, i, 0, { hl_group = marker_hl, end_col = 0 })
		elseif line:match("^%{7,}.*diff%s+from:") then
			vim.api.nvim_buf_set_extmark(bufnr, ns, i, 0, { hl_group = ours_hl, end_col = 0 })
		elseif line:match("^\\{7,}.*to:") then
			vim.api.nvim_buf_set_extmark(bufnr, ns, i, 0, { hl_group = label_hl, end_col = 0 })
		elseif line:match("^%+{7,}") then
			vim.api.nvim_buf_set_extmark(bufnr, ns, i, 0, { hl_group = theirs_hl, end_col = 0 })
		elseif line:match("^%-") then
			vim.api.nvim_buf_set_extmark(bufnr, ns, i, 0, { hl_group = diff_rem_hl, end_col = 0 })
		elseif line:match("^%+") and not line:match("^%+{7,}") then
			vim.api.nvim_buf_set_extmark(bufnr, ns, i, 0, { hl_group = diff_add_hl, end_col = 0 })
		end
	end
end

function M.clear_highlights(bufnr)
	vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
end

return M
