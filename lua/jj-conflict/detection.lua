local M = {}

function M.parse_label(line)
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
		local lnum = i - 1

		local is_start = line:find("^<<<<<<<")
		local is_diff_from = line:find("^%%%%%%%%%%%%%%")
		local is_diff_to = line:find([[^\\\\\\\]])
		local is_snapshot = line:find("^%+%+%+%+%+%+%+")
		local is_end = line:find("^>>>>>>>")

		if is_start then
			local id, total = line:match("[Cc]onflict%s+(%d+)%s+of%s+(%d+)")
			current_conflict = {
				id = tonumber(id) or 0,
				total = tonumber(total) or 0,
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
			elseif current_section == "ours" then
				-- Skip the 'to:' marker line, but capture the actual diff lines
				if not is_diff_to then
					table.insert(current_conflict.ours.lines, line)
				end
			elseif current_section == "theirs" then
				table.insert(current_conflict.theirs.lines, line)
			end
		end
	end
	return conflicts
end

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

	vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "TextChanged", "BufEnter", "BufWinEnter", "FileType" }, {
		group = group,
		pattern = "*",
		callback = function(args)
			local bufnr = args.buf
			if not vim.api.nvim_buf_is_valid(bufnr) then
				return
			end

			-- Modern pickers use hidden nofile buffers and asynchronously inject text 
			-- via nvim_buf_set_lines, which bypasses normal TextChanged/BufRead events.
			-- We robustly attach an on_lines listener to track these updates.
			if vim.bo[bufnr].buftype == "nofile" and not vim.b[bufnr].jj_conflict_attached then
				vim.b[bufnr].jj_conflict_attached = true
				vim.api.nvim_buf_attach(bufnr, false, {
					on_lines = function(_, buf)
						vim.schedule(function()
							if vim.api.nvim_buf_is_valid(buf) then
								require("jj-conflict.highlights").apply_highlights(buf)
							end
						end)
					end
				})
			end

			vim.schedule(function()
				if not vim.api.nvim_buf_is_valid(bufnr) then
					return
				end

				require("jj-conflict.highlights").apply_highlights(bufnr)

				local detection = require("jj-conflict.detection")
				if detection.count_conflicts(bufnr) > 0 then
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
