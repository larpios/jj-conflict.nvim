local M = {}

local detection = require("jj-conflict.detection")
local resolution = require("jj-conflict.resolution")

local CLIENT_NAME = "jj-conflict"

function M.setup()
    local group = vim.api.nvim_create_augroup("JjConflictLSP", { clear = true })
    vim.api.nvim_create_autocmd("User", {
        pattern = "JjConflictDetected",
        group = group,
        callback = function()
            M.attach()
        end,
    })
end

function M.attach(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    -- Only attach to valid file buffers
    if vim.bo[bufnr].buftype ~= "" then
        return
    end

    -- Check if already attached
    local clients = vim.lsp.get_clients({ name = CLIENT_NAME, bufnr = bufnr })
    if #clients > 0 then
        return
    end

    vim.lsp.start({
        name = CLIENT_NAME,
        cmd = function(dispatchers)
            return {
                request = function(method, params, callback)
                    if method == "initialize" then
                        callback(nil, {
                            capabilities = {
                                codeActionProvider = true,
                                executeCommandProvider = {
                                    commands = { "jj-conflict.resolve" },
                                },
                            },
                        })
                    elseif method == "textDocument/codeAction" then
                        local conflict = detection.get_conflict_at_cursor(bufnr)
                        if not conflict then
                            callback(nil, nil)
                            return
                        end

                        local actions = {
                            { title = "Accept Ours", action = "ours" },
                            { title = "Accept Theirs", action = "theirs" },
                            { title = "Accept Both", action = "both" },
                            { title = "Accept Base", action = "base" },
                        }

                        local result = {}
                        for _, a in ipairs(actions) do
                            table.insert(result, {
                                title = a.title,
                                kind = "quickfix",
                                command = {
                                    title = a.title,
                                    command = "jj-conflict.resolve",
                                    arguments = { bufnr, a.action },
                                },
                            })
                        end
                        callback(nil, result)
                    elseif method == "workspace/executeCommand" then
                        if params.command == "jj-conflict.resolve" then
                            local buf = params.arguments[1]
                            local action = params.arguments[2]
                            local conflict = detection.get_conflict_at_cursor(buf)
                            if conflict then
                                vim.schedule(function()
                                    resolution.resolve_conflict(conflict, action)
                                end)
                            end
                        end
                        callback(nil, nil)
                    elseif method == "shutdown" then
                        callback(nil, nil)
                    end
                end,
                notify = function(method, params) end,
                is_closing = function()
                    return false
                end,
                terminate = function() end,
            }
        end,
        root_dir = vim.fn.getcwd(),
    })
end

return M
