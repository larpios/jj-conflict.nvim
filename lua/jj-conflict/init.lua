local M = {}

_G.jj_conflict = setmetatable({}, {
    __index = M
})

---@class JjConflictConflictMapping
---@field ours string Mapping for "ours" side of the conflict
---@field theirs string Mapping for "theirs" side of the conflict
---@field both string Mapping for both sides of the conflict
---@field none string Mapping for none of the conflict
---@field next string Mapping for next conflict
---@field prev string Mapping for previous conflict

---@class JjConflictHighlight
---@field ours string Highlight group for "ours" side of the conflict
---@field theirs string Highlight group for "theirs" side of the conflict
---@field marker string Highlight group for conflict marker
---@field label string Highlight group for conflict label
---@field diff_remove string Highlight group for removed lines
---@field diff_add string Highlight group for added lines

---@class JjConflictConfig
---@field default_mappings boolean Whether to automatically setup default mappings
---@field default_commands boolean Whether to automatically setup default commands
---@field highlights JjConflictHighlight Highlight groups
---@field mappings JjConflictConflictMapping Custom mappings

---@type JjConflictConfig
local default_config = {
	default_mappings = true,
	default_commands = true,
	highlights = {
		ours = "DiffAdd",
		theirs = "DiffText",
		marker = "CursorLine",
		label = "Comment",
		diff_remove = "DiffDelete",
		diff_add = "DiffAdd",
	},
	mappings = {
		ours = "Ho",
		theirs = "Ht",
		both = "Hb",
		none = "H0",
		next = "Hn",
		prev = "Hp",
	},
}

---@param opts? JjConflictConfig
function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", default_config, opts or {})
    _G.jj_conflict.config = M.config

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
