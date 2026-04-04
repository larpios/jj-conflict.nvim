local M = {}

local util = require("jj-conflict.util")
local ui = require("jj-conflict.ui")

---Run a jj command asynchronously and call callback with output
---@param args string[]
---@param on_complete fun(code: integer, stdout: string, stderr: string)
local function jj_run(args, on_complete)
    if not vim.fn.executable("jj") then
        util.notify("jj executable not found in PATH", vim.log.levels.ERROR)
        return
    end

    vim.system(vim.list_extend({ "jj" }, args), { text = true }, function(obj)
        vim.schedule(function()
            on_complete(obj.code, obj.stdout or "", obj.stderr or "")
        end)
    end)
end

function M.squash()
    -- Get recent revisions
    -- Format: change_id (commit_id) | author | description
    jj_run({
        "log",
        "--no-graph",
        "-T",
        'change_id.short() ++ " (" ++ commit_id.short() ++ ") | " ++ description.first_line()\n',
        "-n",
        "20",
    }, function(code, stdout, stderr)
        if code ~= 0 then
            util.notify("Failed to run jj log: " .. stderr, vim.log.levels.ERROR)
            return
        end

        local items = {}
        for line in stdout:gmatch("[^\r\n]+") do
            local rev, desc = line:match("([^|]+)|(.*)")
            if rev and desc then
                rev = vim.trim(rev)
                local change_id = rev:match("^([^%s]+)")
                if change_id then
                    table.insert(items, {
                        text = string.format("%-15s | %s", rev, vim.trim(desc)),
                        change_id = change_id,
                    })
                end
            end
        end

        if #items == 0 then
            util.notify("No revisions found to squash into", vim.log.levels.WARN)
            return
        end

        ui.pick({
            title = "Squash into",
            items = items,
            on_select = function(item)
                if not item.change_id then
                    return
                end
                -- Run jj squash
                jj_run({ "squash", "--into", item.change_id }, function(s_code, s_stdout, s_stderr)
                    if s_code == 0 then
                        util.notify("Squashed into " .. item.change_id, vim.log.levels.INFO)
                        -- Reload buffer if it was affected
                        vim.cmd("checktime")
                    else
                        util.notify("Failed to squash: " .. s_stderr, vim.log.levels.ERROR)
                    end
                end)
            end,
        })
    end)
end

function M.resolve()
    local file = vim.fn.expand("%:p")
    if file == "" then
        util.notify("No file in current buffer", vim.log.levels.WARN)
        return
    end

    jj_run({ "resolve", file }, function(code, stdout, stderr)
        if code == 0 then
            util.notify("Resolved " .. file, vim.log.levels.INFO)
            vim.cmd("edit!") -- Reload to clear markers if jj removed them
        else
            util.notify("Failed to resolve: " .. (stderr ~= "" and stderr or stdout), vim.log.levels.ERROR)
        end
    end)
end

function M.status()
    jj_run({ "status" }, function(code, stdout, stderr)
        if code ~= 0 then
            util.notify("Failed to run jj status: " .. stderr, vim.log.levels.ERROR)
            return
        end

        local items = {}
        for line in stdout:gmatch("[^\r\n]+") do
            -- Basic parsing of status lines (e.g. "M file.txt")
            local status, file = line:match("^(%u[A-Z]?)%s+(.+)$")
            if status and file then
                table.insert(items, {
                    text = string.format("%-2s %s", status, file),
                    filename = file,
                })
            end
        end

        if #items == 0 then
            util.notify("Working copy is clean", vim.log.levels.INFO)
            return
        end

        ui.pick({
            title = "jj status",
            items = items,
        })
    end)
end

function M.log()
    jj_run({
        "log",
        "--no-graph",
        "-T",
        'change_id.short() ++ " (" ++ commit_id.short() ++ ") | " ++ author.email() ++ " | " ++ description.first_line()\n',
        "-n",
        "50",
    }, function(code, stdout, stderr)
        if code ~= 0 then
            util.notify("Failed to run jj log: " .. stderr, vim.log.levels.ERROR)
            return
        end

        local items = {}
        for line in stdout:gmatch("[^\r\n]+") do
            table.insert(items, {
                text = line,
            })
        end

        if #items == 0 then
            util.notify("No log found", vim.log.levels.WARN)
            return
        end

        ui.pick({
            title = "jj log",
            items = items,
            on_select = function(item)
                local change_id = item.text:match("^([^%s]+)")
                if change_id then
                    -- Just show info for now, could expand to show diff
                    util.notify("Selected revision: " .. change_id, vim.log.levels.INFO)
                end
            end,
        })
    end)
end

function M.diff()
    local file = vim.fn.expand("%:p")
    if file == "" then
        util.notify("No file in current buffer", vim.log.levels.WARN)
        return
    end

    jj_run({ "diff", file }, function(code, stdout, stderr)
        if code ~= 0 then
            util.notify("Failed to run jj diff: " .. stderr, vim.log.levels.ERROR)
            return
        end

        if stdout == "" then
            util.notify("No differences found for " .. file, vim.log.levels.INFO)
            return
        end

        -- Open diff in a temporary buffer
        vim.cmd("vnew")
        local bufnr = vim.api.nvim_get_current_buf()
        vim.api.nvim_buf_set_name(bufnr, "jj diff " .. vim.fn.fnamemodify(file, ":t"))
        vim.api.nvim_set_option_value("buftype", "nofile", { buf = bufnr })
        vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = bufnr })
        vim.api.nvim_set_option_value("filetype", "diff", { buf = bufnr })

        local lines = {}
        for line in stdout:gmatch("[^\r\n]+") do
            table.insert(lines, line)
        end
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
        vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
    end)
end

return M
