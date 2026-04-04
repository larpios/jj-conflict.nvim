local M = {}

local detection = require("jj-conflict.detection")
local highlights = require("jj-conflict.highlights")
local util = require("jj-conflict.util")

local function get_chosen_lines(conflict, choice)
	local lines = {}

	local function resolve_ours()
		if conflict.ours and conflict.ours.lines then
			for _, line in ipairs(conflict.ours.lines) do
				local prefix = line:sub(1, 1)
				-- Jujutsu diff markers: keep additions (+) and context (space), ignore removals (-)
				if prefix == "+" or prefix == " " then
					table.insert(lines, line:sub(2))
				elseif prefix == "-" then
					-- Do nothing, drop this line
				else
					-- Fallback for any malformed lines without a prefix
					table.insert(lines, line)
				end
			end
		end
	end

	local function resolve_theirs()
		if conflict.theirs and conflict.theirs.lines then
			for _, line in ipairs(conflict.theirs.lines) do
				-- 'Theirs' is a raw snapshot, so we insert the line exactly as is
				table.insert(lines, line)
			end
		end
	end

	local function resolve_base()
		if conflict.ours and conflict.ours.lines then
			for _, line in ipairs(conflict.ours.lines) do
				local prefix = line:sub(1, 1)
				if prefix == "-" or prefix == " " then
					table.insert(lines, line:sub(2))
				elseif prefix == "+" then
					-- Do nothing, drop this line
				else
					-- Fallback for any malformed lines without a prefix
					table.insert(lines, line)
				end
			end
		end
	end

	if choice == "ours" then
		resolve_ours()
	elseif choice == "theirs" then
		resolve_theirs()
	elseif choice == "both" then
		resolve_ours()
		resolve_theirs()
	elseif choice == "base" then
		resolve_base()
	end

	return lines
end

function M.choose_ours()
	local conflict = detection.get_conflict_at_cursor()
	if not conflict then
		util.notify("No conflict at cursor", vim.log.levels.WARN)
		return
	end
	M.resolve_conflict(conflict, "ours")
end

function M.choose_theirs()
	local conflict = detection.get_conflict_at_cursor()
	if not conflict then
		util.notify("No conflict at cursor", vim.log.levels.WARN)
		return
	end
	M.resolve_conflict(conflict, "theirs")
end

function M.choose_both()
	local conflict = detection.get_conflict_at_cursor()
	if not conflict then
		util.notify("No conflict at cursor", vim.log.levels.WARN)
		return
	end
	M.resolve_conflict(conflict, "both")
end

function M.choose_base()
	local conflict = detection.get_conflict_at_cursor()
	if not conflict then
		util.notify("No conflict at cursor", vim.log.levels.WARN)
		return
	end
	M.resolve_conflict(conflict, "base")
end

function M.resolve_conflict(conflict, choice)
	local bufnr = vim.api.nvim_get_current_buf()
	local lines = get_chosen_lines(conflict, choice)

	vim.api.nvim_buf_set_lines(bufnr, conflict.start_line, conflict.end_line + 1, false, lines)

	highlights.clear_highlights(bufnr)

	local remaining = detection.count_conflicts(bufnr)
	if remaining == 0 then
		vim.api.nvim_exec_autocmds("User", { pattern = "JjConflictResolved", modeline = false })
		util.notify("All conflicts resolved!", vim.log.levels.INFO)
		
		-- Auto-verify with jj if possible
		local file = vim.api.nvim_buf_get_name(bufnr)
		if file ~= "" and vim.fn.executable("jj") == 1 then
			vim.system({ "jj", "status" }, { text = true }, function(obj)
				-- This just triggers jj to update its internal state if it hasn't already.
				-- It doesn't strictly need to notify unless there's an error,
				-- but having it run ensures the next jj command (like jj log) sees the file as resolved.
				if obj.code ~= 0 and obj.stderr then
					vim.schedule(function()
						util.notify("jj verification failed: " .. obj.stderr, vim.log.levels.WARN)
					end)
				end
			end)
		end
	end
end

return M
