local M = {}

local detection = require("jj-conflict.detection")

local cache = {
    workspace = nil,
    time = 0,
}

local function update_workspace()
    local current_time = os.time()
    -- Update at most every 5 seconds to avoid spamming jj
    if current_time - cache.time < 5 then
        return
    end

    if vim.fn.executable("jj") == 1 then
        vim.system({ "jj", "workspace", "root" }, { text = true }, function(obj)
            if obj.code == 0 and obj.stdout then
                local path = vim.trim(obj.stdout)
                cache.workspace = vim.fn.fnamemodify(path, ":t")
            else
                cache.workspace = nil
            end
            cache.time = os.time()
        end)
    end
end

---Get conflict count and optional workspace for current buffer
---@return string
function M.get_status()
    update_workspace()

    local bufnr = vim.api.nvim_get_current_buf()
    local count = detection.count_conflicts(bufnr)

    local parts = {}
    if cache.workspace then
        table.insert(parts, "JJ:" .. cache.workspace)
    else
        table.insert(parts, "JJ")
    end

    if count > 0 then
        table.insert(parts, "✗ " .. count)
    end

    if #parts == 1 and count == 0 then
        return parts[1] -- Just JJ:workspace
    end

    return table.concat(parts, " | ")
end

return M
