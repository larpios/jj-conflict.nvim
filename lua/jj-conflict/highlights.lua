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
	local diff_rem_hl = "JjConflictDiffRemove"
	local diff_add_hl = "JjConflictDiffAdd"

	for i = start_line, end_line do
		local line = vim.api.nvim_buf_get_lines(bufnr, i, i + 1, false)[1] or ""

		if line:match("^<{7,}") or line:match("^>{7,}") then
			vim.api.nvim_buf_add_highlight(bufnr, ns, marker_hl, i, 0, -1)
		elseif line:match("^%^{7,}") or line:match("^%+{7,}") then
			vim.api.nvim_buf_add_highlight(bufnr, ns, theirs_hl, i, 0, -1)
		elseif line:match("^\\\\{4,}") then
			vim.api.nvim_buf_add_highlight(bufnr, ns, "JjConflictLabel", i, 0, -1)
		elseif line:match("^%+%s") then
			vim.api.nvim_buf_add_highlight(bufnr, ns, diff_add_hl, i, 0, -1)
		elseif line:match("^%-") then
			vim.api.nvim_buf_add_highlight(bufnr, ns, diff_rem_hl, i, 0, -1)
		end
	end
end

function M.clear_highlights(bufnr)
	vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
end

return M
