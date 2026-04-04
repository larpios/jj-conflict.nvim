local M = {}
local util = require("jj-conflict.util")

---@alias PickerItem { text: string, lnum?: number, col?: number, bufnr?: number, filename?: string }

---Show a picker with a list of items
---@param opts { title: string, items: PickerItem[], on_select?: fun(item: PickerItem) }
function M.pick(opts)
    local has_snacks, snacks = pcall(require, "snacks")
    local has_fzf, fzf = pcall(require, "fzf-lua")

    if has_snacks and snacks.picker then
        -- Convert to snacks.picker items
        local snacks_items = {}
        for i, item in ipairs(opts.items) do
            table.insert(snacks_items, {
                idx = i,
                text = item.text,
                file = item.filename or (item.bufnr and vim.api.nvim_buf_get_name(item.bufnr)),
                pos = { item.lnum or 1, (item.col or 1) - 1 },
                item = item, -- store original
            })
        end

        snacks.picker.pick({
            title = opts.title,
            items = snacks_items,
            format = "text",
            confirm = function(picker, item)
                picker:close()
                if opts.on_select and item and item.item then
                    opts.on_select(item.item)
                elseif item then
                    -- Default action: jump to file/line
                    if item.file then
                        vim.cmd("edit " .. vim.fn.fnameescape(item.file))
                    elseif item.item.bufnr then
                        vim.api.nvim_set_current_buf(item.item.bufnr)
                    end
                    if item.pos then
                        vim.api.nvim_win_set_cursor(0, { item.pos[1], item.pos[2] })
                        vim.cmd("normal! zv")
                    end
                end
            end,
        })
    elseif has_fzf then
        local fzf_items = {}
        local fzf_lookup = {}
        for _, item in ipairs(opts.items) do
            local file = item.filename or (item.bufnr and vim.api.nvim_buf_get_name(item.bufnr)) or ""
            local display = string.format("%s:%d:%d: %s", file, item.lnum or 1, item.col or 1, item.text)
            table.insert(fzf_items, display)
            fzf_lookup[display] = item
        end

        fzf.fzf_exec(fzf_items, {
            prompt = opts.title .. "> ",
            actions = {
                ["default"] = function(selected)
                    if not selected or not selected[1] then
                        return
                    end
                    local item = fzf_lookup[selected[1]]
                    if not item then
                        return
                    end

                    if opts.on_select then
                        opts.on_select(item)
                    else
                        -- Default action
                        local file = item.filename or (item.bufnr and vim.api.nvim_buf_get_name(item.bufnr))
                        if file and file ~= "" then
                            vim.cmd("edit " .. vim.fn.fnameescape(file))
                        elseif item.bufnr then
                            vim.api.nvim_set_current_buf(item.bufnr)
                        end
                        if item.lnum then
                            vim.api.nvim_win_set_cursor(0, { item.lnum, (item.col or 1) - 1 })
                            vim.cmd("normal! zv")
                        end
                    end
                end,
            },
        })
    else
        -- Fallback to select or quickfix if no custom on_select
        if opts.on_select then
            local format_item = function(item)
                return item.text
            end
            vim.ui.select(opts.items, { prompt = opts.title, format_item = format_item }, function(choice)
                if choice then
                    opts.on_select(choice)
                end
            end)
        else
            local qf_list = {}
            for _, item in ipairs(opts.items) do
                table.insert(qf_list, {
                    bufnr = item.bufnr,
                    filename = item.filename,
                    lnum = item.lnum or 1,
                    col = item.col or 1,
                    text = item.text,
                })
            end
            vim.fn.setloclist(0, qf_list, "r")
            vim.cmd("silent lopen")
            util.notify("Using fallback location list for " .. opts.title)
        end
    end
end

return M
