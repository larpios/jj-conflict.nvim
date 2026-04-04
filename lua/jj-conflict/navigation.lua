local M = {}

local detection = require("jj-conflict.detection")
local highlights = require("jj-conflict.highlights")
local util = require("jj-conflict.util")

function M.next()
    local bufnr = vim.api.nvim_get_current_buf()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local current_line = cursor[1] - 1

    local conflicts = detection.detect_conflicts(bufnr)

    for _, conflict in ipairs(conflicts) do
        if conflict.start_line > current_line then
            vim.api.nvim_win_set_cursor(0, { conflict.start_line + 1, 0 })
            vim.cmd("normal! zv")
            return
        end
    end

    util.notify("No more conflicts", vim.log.levels.WARN)
end

function M.prev()
    local bufnr = vim.api.nvim_get_current_buf()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local current_line = cursor[1] - 1

    local conflicts = detection.detect_conflicts(bufnr)

    for i = #conflicts, 1, -1 do
        local conflict = conflicts[i]
        if conflict.end_line < current_line then
            vim.api.nvim_win_set_cursor(0, { conflict.start_line + 1, 0 })
            vim.cmd("normal! zv")
            return
        end
    end

    util.notify("No previous conflicts", vim.log.levels.WARN)
end

function M.list()
    local bufnr = vim.api.nvim_get_current_buf()
    local conflicts = detection.detect_conflicts(bufnr)
    local file = vim.api.nvim_buf_get_name(bufnr)

    local items = {}
    for _, conflict in ipairs(conflicts) do
        table.insert(items, {
            bufnr = bufnr,
            filename = file,
            lnum = conflict.start_line + 1,
            col = 1,
            text = string.format("Conflict %d", conflict.id),
        })
    end

    if #items > 0 then
        local ui = require("jj-conflict.ui")
        ui.pick({
            title = "jj conflicts",
            items = items,
        })
        util.notify(string.format("Found %d conflicts", #conflicts), vim.log.levels.INFO)
    else
        util.notify("No conflicts found", vim.log.levels.INFO)
    end
end

return M
