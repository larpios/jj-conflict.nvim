local M = {}

local config = require("jj-conflict.init").config

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
	local opts = { buffer = bufnr, silent = true, noremap = true }

	local cfg = require("jj-conflict.init").config
	local maps = cfg.mappings

	vim.keymap.set("n", maps.ours, "<Plug>(jj-conflict-ours)", opts)
	vim.keymap.set("n", maps.theirs, "<Plug>(jj-conflict-theirs)", opts)
	vim.keymap.set("n", maps.both, "<Plug>(jj-conflict-both)", opts)
	vim.keymap.set("n", maps.none, "<Plug>(jj-conflict-none)", opts)
	vim.keymap.set("n", "]" .. maps.next, "<Plug>(jj-conflict-next-conflict)", opts)
	vim.keymap.set("n", "[" .. maps.prev, "<Plug>(jj-conflict-prev-conflict)", opts)

	vim.keymap.set("n", "<Plug>(jj-conflict-ours)", function()
		require("jj-conflict.resolution").choose_ours()
	end, opts)
	vim.keymap.set("n", "<Plug>(jj-conflict-theirs)", function()
		require("jj-conflict.resolution").choose_theirs()
	end, opts)
	vim.keymap.set("n", "<Plug>(jj-conflict-both)", function()
		require("jj-conflict.resolution").choose_both()
	end, opts)
	vim.keymap.set("n", "<Plug>(jj-conflict-none)", function()
		require("jj-conflict.resolution").choose_none()
	end, opts)
	vim.keymap.set("n", "<Plug>(jj-conflict-next-conflict)", function()
		require("jj-conflict.navigation").next()
	end, opts)
	vim.keymap.set("n", "<Plug>(jj-conflict-prev-conflict)", function()
		require("jj-conflict.navigation").prev()
	end, opts)
end

return M
