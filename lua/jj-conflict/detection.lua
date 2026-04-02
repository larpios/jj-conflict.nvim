local M = {}

M.patterns = {
	start = "^<{7,}.*conflict%s+(%d+)%s+of%s+(%d+)",
	diff_start = "^%{7,}.*diff%s+from:",
	diff_to = "^\\{7,}.*to:",
	snapshot_start = "^%+{7,}",
	end_marker = "^>{7,}.*ends?$",
}

function M.detect_conflicts(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

	local conflicts = {}
	local current_conflict = nil
	local current_section = nil

	for i, line in ipairs(lines) do
		local start_match = string.match(line, M.patterns.start)
		local diff_match = string.match(line, M.patterns.diff_start)
		local diff_to_match = string.match(line, M.patterns.diff_to)
		local snapshot_match = string.match(line, M.patterns.snapshot_start)
		local end_match = string.match(line, M.patterns.end_marker)

		if start_match then
			local conflict_num = tonumber(start_match)
			current_conflict = {
				id = conflict_num,
				start_line = i - 1,
				ours = nil,
				theirs = nil,
				ours_label = nil,
				theirs_label = nil,
			}
			current_section = "start"
		elseif current_conflict then
			if diff_match then
				local commit_id, msg = M.parse_label(line, "diff from:")
				current_conflict.ours_label = { commit_id = commit_id, msg = msg }
				current_section = "ours"
				current_conflict.ours = { start_line = i - 1, lines = {} }
			elseif diff_to_match then
			-- Continuation of diff label, skip
			elseif snapshot_match then
				local commit_id, msg = M.parse_label(line, "")
				current_conflict.theirs_label = { commit_id = commit_id, msg = msg }
				current_section = "theirs"
				current_conflict.theirs = { start_line = i - 1, lines = {} }
			elseif end_match then
				current_conflict.end_line = i - 1
				table.insert(conflicts, current_conflict)
				current_conflict = nil
				current_section = nil
			elseif current_section == "ours" then
				if line:match("^%-%s") then
					table.insert(current_conflict.ours.lines, { type = "remove", text = line:sub(3) })
				elseif line:match("^%+%s") then
					table.insert(current_conflict.ours.lines, { type = "add", text = line:sub(3) })
				else
					table.insert(current_conflict.ours.lines, { type = "context", text = line })
				end
			elseif current_section == "theirs" then
				table.insert(current_conflict.theirs.lines, line)
			end
		end
	end

	return conflicts
end

function M.parse_label(line, prefix)
	local commit_pattern = '([a-z0-9]+)%s+"(.*)"'
	local commit_id, msg = string.match(line, commit_pattern)
	return commit_id, msg
end

function M.has_conflicts(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local conflicts = M.detect_conflicts(bufnr)
	return #conflicts > 0, conflicts
end

function M.get_conflict_at_cursor(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local line = cursor[1] - 1
	local conflicts = M.detect_conflicts(bufnr)

	for _, conflict in ipairs(conflicts) do
		if conflict.start_line <= line and line <= conflict.end_line then
			return conflict
		end
	end

	return nil
end

function M.count_conflicts(bufnr)
	local _, conflicts = M.has_conflicts(bufnr)
	return #conflicts
end

function M.start_autocmds()
	local group = vim.api.nvim_create_augroup("JjConflictDetection", { clear = true })

	vim.api.nvim_create_autocmd("BufReadPost", {
		group = group,
		pattern = "*",
		callback = function(args)
			local bufnr = args.buf
			vim.schedule(function()
				local has_conflicts, conflicts = M.has_conflicts(bufnr)
				if has_conflicts then
					vim.api.nvim_exec_autocmds("User", { pattern = "JjConflictDetected", modeline = false })
				end
			end)
		end,
	})
end

return M
