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

	vim.api.nvim_create_user_command("JjConflictChooseNone", function()
		require("jj-conflict.resolution").choose_none()
	end, { range = true, desc = "Choose none of the conflict" })

	vim.api.nvim_create_user_command("JjConflictNextConflict", function()
		require("jj-conflict.navigation").next()
	end, { desc = "Jump to next conflict" })

	vim.api.nvim_create_user_command("JjConflictPrevConflict", function()
		require("jj-conflict.navigation").prev()
	end, { desc = "Jump to previous conflict" })

	vim.api.nvim_create_user_command("JjConflictList", function()
		require("jj-conflict.navigation").list()
	end, { desc = "List all conflicts in location list" })
end

return M
