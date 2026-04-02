local M = {}

local detection = require("jj-conflict.detection")
local highlights = require("jj-conflict.highlights")
local navigation = require("jj-conflict.navigation")

local function get_chosen_lines(conflict, choice)
	local lines = {}

	if choice == "ours" then
		if conflict.ours and conflict.ours.lines then
			for _, line in ipairs(conflict.ours.lines) do
				if line.type == "context" then
					table.insert(lines, line.text)
				elseif line.type == "add" then
					table.insert(lines, line.text)
				end
			end
		end
	elseif choice == "theirs" then
		if conflict.theirs and conflict.theirs.lines then
			for _, line in ipairs(conflict.theirs.lines) do
				table.insert(lines, line)
			end
		end
	elseif choice == "both" then
		if conflict.ours and conflict.ours.lines then
			for _, line in ipairs(conflict.ours.lines) do
				if line.type == "context" then
					table.insert(lines, line.text)
				elseif line.type == "add" then
					table.insert(lines, line.text)
				end
			end
		end
		if conflict.theirs and conflict.theirs.lines then
			for _, line in ipairs(conflict.theirs.lines) do
				table.insert(lines, line)
			end
		end
	elseif choice == "none" then
		-- Nothing, just empty
	end

	return lines
end

function M.choose_ours()
	local conflict = detection.get_conflict_at_cursor()
	if not conflict then
		vim.notify("No conflict at cursor", vim.log.levels.WARN)
		return
	end
	M.resolve_conflict(conflict, "ours")
end

function M.choose_theirs()
	local conflict = detection.get_conflict_at_cursor()
	if not conflict then
		vim.notify("No conflict at cursor", vim.log.levels.WARN)
		return
	end
	M.resolve_conflict(conflict, "theirs")
end

function M.choose_both()
	local conflict = detection.get_conflict_at_cursor()
	if not conflict then
		vim.notify("No conflict at cursor", vim.log.levels.WARN)
		return
	end
	M.resolve_conflict(conflict, "both")
end

function M.choose_none()
	local conflict = detection.get_conflict_at_cursor()
	if not conflict then
		vim.notify("No conflict at cursor", vim.log.levels.WARN)
		return
	end
	M.resolve_conflict(conflict, "none")
end

function M.resolve_conflict(conflict, choice)
	local bufnr = vim.api.nvim_get_current_buf()
	local lines = get_chosen_lines(conflict, choice)

	vim.api.nvim_buf_set_lines(bufnr, conflict.start_line, conflict.end_line + 1, false, lines)

	highlights.clear_highlights(bufnr)

	local remaining = detection.count_conflicts(bufnr)
	if remaining == 0 then
		vim.api.nvim_exec_autocmds("User", { pattern = "JjConflictResolved", modeline = false })
		vim.notify("All conflicts resolved!", vim.log.levels.INFO)
	end
end

return M
