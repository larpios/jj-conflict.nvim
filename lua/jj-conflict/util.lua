local M = {}
local config = require("jj-conflict.config")

function M.notify(msg, level)
    if config.config.notify then
        vim.notify(msg, level)
    end
end

return M