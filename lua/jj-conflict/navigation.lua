local M = {}

local detection = require("jj-conflict.detection")
local highlights = require("jj-conflict.highlights")

function M.next()
	local bufnr = vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local current_line = cursor[1] - 1

	local conflicts = detection.detect_conflicts(bufnr)

	for _, conflict in ipairs(conflicts) do
		if conflict.start_line > current_line then
			vim.api.nvim_win_set_cursor(0, { conflict.start_line + 1, 0 })
			vim.cmd("normal! zv")
			return
		end
	end

	vim.notify("No more conflicts", vim.log.levels.WARN)
end

function M.prev()
	local bufnr = vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local current_line = cursor[1] - 1

	local conflicts = detection.detect_conflicts(bufnr)

	for i = #conflicts, 1, -1 do
		local conflict = conflicts[i]
		if conflict.end_line < current_line then
			vim.api.nvim_win_set_cursor(0, { conflict.start_line + 1, 0 })
			vim.cmd("normal! zv")
			return
		end
	end

	vim.notify("No previous conflicts", vim.log.levels.WARN)
end

function M.list()
	local bufnr = vim.api.nvim_get_current_buf()
	local conflicts = detection.detect_conflicts(bufnr)
	local file = vim.api.nvim_buf_get_name(bufnr)

	local qf_list = {}
	for _, conflict in ipairs(conflicts) do
		table.insert(qf_list, {
			bufnr = bufnr,
			lnum = conflict.start_line + 1,
			col = 1,
			text = string.format("Conflict %d", conflict.id),
		})
	end

	if #qf_list > 0 then
		vim.fn.setloclist(0, qf_list, "r")
		vim.cmd("silent lopen")
		vim.notify(string.format("Found %d conflicts", #conflicts))
	else
		vim.notify("No conflicts found", vim.log.levels.INFO)
	end
end

return M
