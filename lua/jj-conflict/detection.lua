local M = {}

M.patterns = {
    start = "^<<<<<<<[<]*%s*[Cc]onflict%s+(%d+)%s+of%s+(%d+)",
    diff_start = "^%%%%%%%[%%]*.*diff%s+from:", 
    diff_to = "^\\\\\\\\\\\\\\%s*to:", 
    snapshot_start = "^%+%+%+%+%+%+%+[%+]*",
    end_marker = "^>>>>>>>[>]*.*[Ee]nds?",
}

--- Parse commit ID and message safely
function M.parse_label(line)
	-- Improved pattern to handle varied spacing and missing quotes
	local commit_id, msg = string.match(line, '([a-z0-9]+)%s+"?([^"]*)"?')
	return commit_id or "unknown", msg or ""
end

function M.detect_conflicts(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return {}
	end

	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local conflicts = {}
	local current_conflict = nil
	local current_section = nil

	for i, line in ipairs(lines) do
		local lnum = i - 1 -- 0-indexed line number for Neovim API

		-- Match against patterns
		local start_id, total = line:match(M.patterns.start)
		local is_diff_from = line:match(M.patterns.diff_start)
		local is_diff_to = line:match(M.patterns.diff_to)
		local is_snapshot = line:match(M.patterns.snapshot_start)
		local is_end = line:match(M.patterns.end_marker)

		if start_id then
			current_conflict = {
				id = tonumber(start_id),
				total = tonumber(total),
				start_line = lnum,
				ours = { lines = {} },
				theirs = { lines = {} },
			}
			current_section = "metadata"
		elseif current_conflict then
			if is_diff_from then
				current_conflict.ours.start_line = lnum
				current_section = "ours"
			elseif is_snapshot then
				current_conflict.theirs.start_line = lnum
				current_section = "theirs"
			elseif is_end then
				current_conflict.end_line = lnum
				table.insert(conflicts, current_conflict)
				current_conflict = nil
				current_section = nil
			elseif current_section == "ours" and not is_diff_to then
				-- logic for parsing diff lines (+/-)
				table.insert(current_conflict.ours.lines, line)
			elseif current_section == "theirs" then
				table.insert(current_conflict.theirs.lines, line)
			end
		end
	end
	return conflicts
end

-- Refactored to avoid redundant detection logic
function M.get_conflict_at_cursor(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local current_line = cursor[1] - 1

	local conflicts = M.detect_conflicts(bufnr)
	for _, conflict in ipairs(conflicts) do
		if current_line >= conflict.start_line and current_line <= conflict.end_line then
			return conflict
		end
	end
	return nil
end

function M.has_conflicts(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local conflicts = M.detect_conflicts(bufnr)
	return #conflicts > 0, conflicts
end

function M.count_conflicts(bufnr)
	local _, conflicts = M.has_conflicts(bufnr)
	return #conflicts
end

function M.start_autocmds()
	local group = vim.api.nvim_create_augroup("JjConflictDetection", { clear = true })

	vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "TextChanged" }, {
		group = group,
		pattern = "*",
		callback = function(args)
			-- Use a small debounce or schedule to prevent lag on rapid typing
			vim.schedule(function()
				if not vim.api.nvim_buf_is_valid(args.buf) then
					return
				end

				local conflicts = M.detect_conflicts(args.buf)
				local highlights = require("jj-conflict.highlights")

				highlights.clear_highlights(args.buf)

				if #conflicts > 0 then
					for _, conflict in ipairs(conflicts) do
						highlights.highlight_conflict(args.buf, conflict)
					end
					vim.api.nvim_exec_autocmds("User", {
						pattern = "JjConflictDetected",
						modeline = false,
					})
				end
			end)
		end,
	})
end

return M
