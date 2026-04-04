local M = {}

M.detection = require("jj-conflict.detection")
M.highlights = require("jj-conflict.highlights")
M.resolution = require("jj-conflict.resolution")
M.navigation = require("jj-conflict.navigation")
M.jj = require("jj-conflict.jj")

function M.conflict_count(bufnr)
    return M.detection.count_conflicts(bufnr)
end

function M.has_conflicts(bufnr)
    return M.detection.has_conflicts(bufnr)
end

function M.get_conflict_at_cursor(bufnr)
    return M.detection.get_conflict_at_cursor(bufnr)
end

return M
