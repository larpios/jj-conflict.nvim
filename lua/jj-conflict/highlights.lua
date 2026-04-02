local M = {}

local ns = vim.api.nvim_create_namespace("jj-conflict")
M.ns = ns

local default_highlights = {
	Ours = { link = "DiffAdd" },
	Theirs = { link = "DiffText" },
	Marker = { link = "Title" },
	Label = { link = "Comment" },
	DiffRemove = { link = "DiffDelete" },
	DiffAdd = { link = "DiffAdd" },
}
function M.setup()
	for name, settings in pairs(default_highlights) do
		vim.api.nvim_set_hl(0, "JjConflict" .. name, settings)
	end
end

function M.highlight_conflict(bufnr, conflict)
	local start_line = conflict.start_line
	local end_line = conflict.end_line

	vim.api.nvim_buf_clear_namespace(bufnr, ns, start_line, end_line + 1)

	for i = start_line, end_line do
		local line = vim.api.nvim_buf_get_lines(bufnr, i, i + 1, false)[1] or ""
		local hl_group = nil

		if line:find("^<<<<<<<") or line:find("^>>>>>>>") then
			hl_group = "JjConflictMarker"
		elseif line:find("^%%%%%%%%%%%%%%") then
			hl_group = "JjConflictOurs"
		elseif line:find([[^\\\\\\\]]) then
			hl_group = "JjConflictLabel"
		elseif line:find("^%+%+%+%+%+%+%+") then
			hl_group = "JjConflictTheirs"
		elseif line:sub(1, 1) == "-" then
			hl_group = "JjConflictDiffRemove"
		elseif line:sub(1, 1) == "+" and not line:find("^%+%+%+%+%+%+%+") then
			hl_group = "JjConflictDiffAdd"
		end

		if hl_group then
			vim.api.nvim_buf_set_extmark(bufnr, ns, i, 0, {
				end_col = #line,
				hl_group = hl_group,
				hl_eol = true,
				priority = 100,
			})
		end
	end
end

function M.clear_highlights(bufnr)
	vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
end

return M
