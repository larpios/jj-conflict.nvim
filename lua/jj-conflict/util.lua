local M = {}
local config = require("jj-conflict.config")

function M.notify(msg, level)
	if config.config.notify then
		local has_snacks, snacks = pcall(require, "snacks")
		if has_snacks and snacks.notify then
			snacks.notify(msg, { level = level, title = "jj-conflict" })
		else
			vim.notify(msg, level)
		end
	end
end

return M