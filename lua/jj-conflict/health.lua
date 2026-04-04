local M = {}

local health = vim.health or require("health")

function M.check()
    health.report_start("jj-conflict.nvim report")

    -- Check for jj CLI
    if vim.fn.executable("jj") == 1 then
        local handle = io.popen("jj --version")
        if handle then
            local result = handle:read("*a")
            handle:close()
            health.report_ok("jj CLI is installed: " .. vim.trim(result))
        else
            health.report_warn("jj CLI is installed but could not get version.")
        end
    else
        health.report_error("jj CLI is not installed or not in PATH. Please install it: https://github.com/jj-vcs/jj")
    end

    -- Check Neovim version
    if vim.fn.has("nvim-0.10") == 1 then
        health.report_ok("Neovim version is 0.10+")
    else
        health.report_warn("Neovim version is less than 0.10. Some features might not work as expected.")
    end

    -- Check highlights
    local highlights = require("jj-conflict.config").config.highlights
    for name, hl in pairs(highlights) do
        if vim.fn.hlexists(hl) == 0 then
            health.report_warn(string.format("Highlight group '%s' (used for '%s') does not exist.", hl, name))
        end
    end
end

return M
