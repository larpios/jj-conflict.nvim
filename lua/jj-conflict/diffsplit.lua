local M = {}

local detection = require("jj-conflict.detection")
local resolution = require("jj-conflict.resolution")
local util = require("jj-conflict.util")

local config = require("jj-conflict.config")

function M.open()
    local conflict = detection.get_conflict_at_cursor()
    if not conflict then
        util.notify("No conflict at cursor", vim.log.levels.WARN)
        return
    end

    local ours = resolution.get_chosen_lines(conflict, "ours")
    local theirs = resolution.get_chosen_lines(conflict, "theirs")
    local base = resolution.get_chosen_lines(conflict, "base")

    local main_buf = vim.api.nvim_get_current_buf()
    local ft = vim.bo[main_buf].filetype

    -- Check for codediff.nvim integration
    local has_codediff, codediff = pcall(require, "codediff")
    if config.config.use_codediff and has_codediff then
        -- codediff.nvim 2.0+ merge tool
        -- We write to temporary files because codediff usually operates on files for stability
        local function temp_file(content, suffix)
            local path = vim.fn.tempname() .. suffix
            vim.fn.writefile(content, path)
            return path
        end

        local p_ours = temp_file(ours, "_ours." .. ft)
        local p_base = temp_file(base, "_base." .. ft)
        local p_theirs = temp_file(theirs, "_theirs." .. ft)

        -- Invoke codediff merge if available, otherwise fallback
        if type(codediff.merge) == "function" then
            local ok, err = pcall(codediff.merge, p_base, p_ours, p_theirs)
            if ok then
                return
            else
                util.notify("codediff.merge failed: " .. tostring(err), vim.log.levels.WARN)
            end
        elseif vim.fn.exists(":CodeDiffMerge") == 2 then
            local ok, err = pcall(vim.cmd, string.format("CodeDiffMerge %s %s %s", p_base, p_ours, p_theirs))
            if ok then
                return
            else
                util.notify("CodeDiffMerge command failed: " .. tostring(err), vim.log.levels.WARN)
            end
        end
        util.notify("codediff.nvim integration failed, falling back to native diff", vim.log.levels.INFO)
    end

    -- Fallback to native 3-way split
    -- Open in a new tab for a clean workspace
    vim.cmd("tabnew")
    local win_base = vim.api.nvim_get_current_win()

    local function setup_buf(content, name)
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
        vim.bo[buf].filetype = ft
        vim.bo[buf].bufhidden = "wipe"
        vim.api.nvim_buf_set_name(buf, name)
        return buf
    end

    local b_ours = setup_buf(ours, "Ours")
    local b_base = setup_buf(base, "Base")
    local b_theirs = setup_buf(theirs, "Theirs")

    -- Setup windows
    vim.api.nvim_win_set_buf(win_base, b_base)
    vim.cmd("diffthis")

    vim.cmd("leftabove vsplit")
    local win_ours = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win_ours, b_ours)
    vim.cmd("diffthis")

    vim.api.nvim_set_current_win(win_base)
    vim.cmd("rightbelow vsplit")
    local win_theirs = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win_theirs, b_theirs)
    vim.cmd("diffthis")

    -- Focus on base
    vim.api.nvim_set_current_win(win_base)
end

return M
