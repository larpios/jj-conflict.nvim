local M = {}

local config = require("jj-conflict.config")

local ns = vim.api.nvim_create_namespace("jj-conflict")
M.ns = ns

local default_highlights = {
    Ours = { link = "DiffAdd" },
    Theirs = { link = "DiffText" },
    Marker = { link = "Title" },
    Label = { link = "Comment" },
    DiffRemove = { link = "DiffDelete" },
    DiffAdd = { link = "DiffAdd" },
}
function M.setup()
    for name, settings in pairs(default_highlights) do
        vim.api.nvim_set_hl(0, "JjConflict" .. name, settings)
    end
end

function M.highlight_conflict(bufnr, conflict)
    local start_line = conflict.start_line
    local end_line = conflict.end_line
    local conf = config.config

    vim.api.nvim_buf_clear_namespace(bufnr, ns, start_line, end_line + 1)

    for i = start_line, end_line do
        local line = vim.api.nvim_buf_get_lines(bufnr, i, i + 1, false)[1] or ""
        local hl_group = nil
        local extmark_opts = {
            hl_eol = true,
            priority = 1000,
        }

        if line:find("^<<<<<<<") or line:find("^>>>>>>>") then
            hl_group = "JjConflictMarker"
            if conf.signs then
                extmark_opts.sign_text = "!!"
                extmark_opts.sign_hl_group = "JjConflictMarker"
            end
        elseif line:find("^%%%%%%%%%%%%%%") then
            hl_group = "JjConflictOurs"
            if conf.virt_text and conflict.ours.commit then
                extmark_opts.virt_text = {
                    { " (Commit: " .. conflict.ours.commit .. " - " .. conflict.ours.message .. ")", "JjConflictLabel" },
                }
            end
            if conf.signs then
                extmark_opts.sign_text = "O>"
                extmark_opts.sign_hl_group = "JjConflictOurs"
            end
        elseif line:find([[^\\\\\\\]]) then
            hl_group = "JjConflictLabel"
        elseif line:find("^%+%+%+%+%+%+%+") then
            hl_group = "JjConflictTheirs"
            if conf.virt_text and conflict.theirs.commit then
                extmark_opts.virt_text = {
                    {
                        " (Commit: " .. conflict.theirs.commit .. " - " .. conflict.theirs.message .. ")",
                        "JjConflictLabel",
                    },
                }
            end
            if conf.signs then
                extmark_opts.sign_text = "T>"
                extmark_opts.sign_hl_group = "JjConflictTheirs"
            end
        elseif line:sub(1, 1) == "-" then
            hl_group = "JjConflictDiffRemove"
        elseif line:sub(1, 1) == "+" and not line:find("^%+%+%+%+%+%+%+") then
            hl_group = "JjConflictDiffAdd"
        end

        if hl_group then
            extmark_opts.hl_group = hl_group
            extmark_opts.end_col = #line
            vim.api.nvim_buf_set_extmark(bufnr, ns, i, 0, extmark_opts)
        end
    end
end

function M.clear_highlights(bufnr)
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
end

function M.apply_highlights(bufnr)
    if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end
    local detection = require("jj-conflict.detection")
    local conflicts = detection.detect_conflicts(bufnr)
    M.clear_highlights(bufnr)
    for _, conflict in ipairs(conflicts) do
        M.highlight_conflict(bufnr, conflict)
    end
end

return M
