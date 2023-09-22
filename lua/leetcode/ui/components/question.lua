local log = require("leetcode.logger")
local gql = require("leetcode.graphql")

local Line = require("nui.line")
local Split = require("nui.split")
local parser = require("leetcode.parser")

---@class lc.Ui.Components.Problem
local M = {}

---@type integer, NuiSplit
local curr_line, split

---Increment current line
---
---@return nil
local function inc_line() curr_line = curr_line + 1 end

---@param title any
function M.title(title)
    local line = Line()

    line:append(title.questionFrontendId .. ". " .. title.title)

    return line
end

---@param title_slug string
function M.link(title_slug)
    local line = Line()

    line:append("https://leetcode.com/problems/" .. title_slug .. "/", "Comment")
    line:append("")

    return line
end

---@param title any
function M.stats(title)
    local line = Line()

    line:append(
        title.difficulty,
        title.difficulty == "Easy" and "DiagnosticOk"
        or title.difficulty == "Medium" and "DiagnosticWarn"
        or "DiagnosticError"
    )
    line:append(" | ")
    line:append(title.likes .. "  ", "Comment")
    line:append(title.dislikes .. "  ", "Comment")

    return line
end

---@param content string
---
---@return nil
function M.content(content)
    -- local s = vim.gsplit(content, "\n", {})

    parser.parse(content):render(split.bufnr, -1, curr_line)
    -- for l in s do
    --     parser.parse(l):render(split.bufnr, -1, curr_line)
    --     inc_line()
    -- end
end

---@param html string
---
---@return NuiLine[]
function M.follow_up(html) end

---Render question split
---
---@param question lc.Problem
---
---@return nil
function M.open(question)
    split = Split({
        relative = "editor",
        position = "left",
        -- size = "40%",
        buf_options = {
            modifiable = true,
            readonly = false,
            filetype = "leetcode.nvim",
            swapfile = false,
            buftype = "nofile",
            buflisted = true,
        },
        win_options = {
            -- winblend = 10,
            -- winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
            foldcolumn = "1",
            wrap = true,
            number = false,
            signcolumn = "no",
        },
        enter = true,
        focusable = true,
    })
    split:mount()

    M.link(question.title_slug):render(split.bufnr, -1, curr_line)
    inc_line()

    M.title(title):render(split.bufnr, -1, curr_line)
    inc_line()

    M.stats(title):render(split.bufnr, -1, curr_line)
    inc_line()

    M.content(content)
end

return M
