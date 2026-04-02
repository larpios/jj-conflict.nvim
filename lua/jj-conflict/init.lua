local M = {}

local config = require("jj-conflict.config")

---@param opts? JjConflictConfig
function M.setup(opts)
	config.merge(opts)

	require("jj-conflict.highlights").setup()

	if config.config.default_commands then
		require("jj-conflict.commands").setup()
	end

	if config.config.default_mappings then
		require("jj-conflict.mappings").setup()
	end

	require("jj-conflict.detection").start_autocmds()
end

M.api = require("jj-conflict.api")

return M
