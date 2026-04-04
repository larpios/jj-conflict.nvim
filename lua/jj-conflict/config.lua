---@class JjConflictConflictMapping
---@field ours string Mapping for "ours" side of the conflict
---@field theirs string Mapping for "theirs" side of the conflict
---@field both string Mapping for both sides of the conflict
---@field base string Mapping for base of the conflict
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
---@field notify boolean Whether to show notifications
---@field desc_prefix string? Prefix for keybinding descriptions
---@field highlights JjConflictHighlight Highlight groups
---@field mappings JjConflictConflictMapping Custom mappings

local M = {}

---@type JjConflictConfig
M.default = {
	default_mappings = true,
	default_commands = true,
	notify = true,
    desc_prefix = nil,
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
		base = "H0",
		next = "Hn",
		prev = "Hp",
	},
}

M.config = M.default

---@param opts? JjConflictConfig
---@return JjConflictConfig
function M.merge(opts)
	M.config = vim.tbl_deep_extend("force", M.default, opts or {})
	return M.config
end

return M
