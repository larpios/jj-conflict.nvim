local default_config = {
	default_mappings = true,
	default_commands = true,
	disable_diagnostics = false,
	highlights = {
		ours = "DiffAdd",
		theirs = "DiffText",
		marker = "CursorLine",
		label = "Comment",
		diff_remove = "DiffDelete",
		diff_add = "DiffAdd",
	},
	mappings = {
		ours = "o",
		theirs = "t",
		both = "b",
		none = "0",
		next = "n",
		prev = "p",
	},
}

local M = {
	config = vim.deepcopy(default_config),
}

function M.setup(user_config)
	M.config = vim.tbl_deep_extend("force", default_config, user_config or {})

	require("jj-conflict.highlights").setup()

	if M.config.default_commands then
		require("jj-conflict.commands").setup()
	end

	if M.config.default_mappings then
		require("jj-conflict.mappings").setup()
	end

	require("jj-conflict.detection").start_autocmds()
end

M.api = require("jj-conflict.api")

return M
