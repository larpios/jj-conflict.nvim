local M = {}
local config = require("jj-conflict.config")
function M.setup()
	local group = vim.api.nvim_create_augroup("JjConflictMappings", { clear = true })

	vim.api.nvim_create_autocmd("BufEnter", {
		group = group,
		pattern = "*",
		callback = function(args)
			local bufnr = args.buf
			local has_conflicts, _ = require("jj-conflict.detection").has_conflicts(bufnr)

			if has_conflicts then
				M.create_buffer_mappings(bufnr)
				require("jj-conflict.highlights").setup()
				local conflicts = require("jj-conflict.detection").detect_conflicts(bufnr)
				for _, conflict in ipairs(conflicts) do
					require("jj-conflict.highlights").highlight_conflict(bufnr, conflict)
				end
			end
		end,
	})
end

function M.create_buffer_mappings(bufnr)
	---@class LocalMapOpts: vim.keymap.set.Opts
	---@field mode? string

	---@param opts? LocalMapOpts
	local map = function(lhs, rhs, opts)
		local default_opts = { buffer = bufnr, silent = true, noremap = true }
		opts = vim.tbl_deep_extend("force", default_opts, opts or {})

		local mode = "n"
		if opts.mode then
			mode = opts.mode
			opts.mode = nil
		end

		vim.keymap.set(mode, lhs, rhs, opts)
	end

	local cfg = config.config
	local maps = cfg.mappings

	map(maps.ours, "<Cmd>JjConflictChooseOurs<CR>", { desc = "Choose our side of the conflict" })
	map(maps.theirs, "<Cmd>JjConflictChooseTheirs<CR>", { desc = "Choose their side of the conflict" })
	map(maps.both, "<Cmd>JjConflictChooseBoth<CR>", { desc = "Choose both sides of the conflict" })
	map(maps.base, "<Cmd>JjConflictChooseBase<CR>", { desc = "Choose base of the conflict" })
	map(maps.next, "<Cmd>JjConflictNextConflict<CR>", { desc = "Jump to next conflict" })
	map(maps.prev, "<Cmd>JjConflictPrevConflict<CR>", { desc = "Jump to previous conflict" })
end

return M
