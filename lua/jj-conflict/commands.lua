local M = {}

function M.setup()
	vim.api.nvim_create_user_command("JjConflictChooseOurs", function()
		require("jj-conflict.resolution").choose_ours()
	end, { range = true, desc = "Choose our side of the conflict" })

	vim.api.nvim_create_user_command("JjConflictChooseTheirs", function()
		require("jj-conflict.resolution").choose_theirs()
	end, { range = true, desc = "Choose their side of the conflict" })

	vim.api.nvim_create_user_command("JjConflictChooseBoth", function()
		require("jj-conflict.resolution").choose_both()
	end, { range = true, desc = "Choose both sides of the conflict" })

	vim.api.nvim_create_user_command("JjConflictChooseBase", function()
		require("jj-conflict.resolution").choose_base()
	end, { range = true, desc = "Choose base of the conflict" })

	vim.api.nvim_create_user_command("JjConflictNextConflict", function()
		require("jj-conflict.navigation").next()
	end, { desc = "Jump to next conflict" })

	vim.api.nvim_create_user_command("JjConflictPrevConflict", function()
		require("jj-conflict.navigation").prev()
	end, { desc = "Jump to previous conflict" })

	vim.api.nvim_create_user_command("JjConflictList", function()
		require("jj-conflict.navigation").list()
	end, { desc = "List all conflicts in UI picker" })

	vim.api.nvim_create_user_command("JjConflictSquash", function()
		require("jj-conflict.jj").squash()
	end, { desc = "Squash current changes into another revision" })

	vim.api.nvim_create_user_command("JjConflictResolve", function()
		require("jj-conflict.jj").resolve()
	end, { desc = "Run jj resolve for the current buffer" })

	vim.api.nvim_create_user_command("JjConflictStatus", function()
		require("jj-conflict.jj").status()
	end, { desc = "Show jj status in a picker" })

	vim.api.nvim_create_user_command("JjConflictLog", function()
		require("jj-conflict.jj").log()
	end, { desc = "Show jj log in a picker" })

	vim.api.nvim_create_user_command("JjConflictDiff", function()
		require("jj-conflict.jj").diff()
	end, { desc = "Show jj diff for the current buffer" })
end

return M
