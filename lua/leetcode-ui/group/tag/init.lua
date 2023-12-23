local theme = require("leetcode.theme")
local u = require("leetcode-ui.utils")

local utils = require("leetcode.parser.utils")
local Group = require("leetcode-ui.group")
local Indent = require("nui.text")

local ts = vim.treesitter

local log = require("leetcode.logger")

---@class lc.ui.Tag : lc.ui.Group
---@field name string
---@field tags lc.ui.Tag[]
---@field node TSNode
---@field text string
local Tag = Group:extend("LeetTag")

function Tag:add_indent(item)
    if item.class and item.class.name == "LeetLine" then
        table.insert(item._texts, 1, Indent("\t", "leetcode_indent"))
        return
    end

    for _, c in ipairs(item:contents()) do
        self:add_indent(c)
    end
end

function Tag:get_text(node) return ts.get_node_text(node, self.text) end

---@param node TSNode
---
---@return lc.Parser.Tag.Attr
function Tag:get_attr(node)
    local attr = {}

    for child in node:iter_children() do
        local ntype = child:type()

        if ntype == "attribute_name" and child:named() then
            attr.name = self:get_text(child)
        elseif ntype == "quoted_attribute_value" and child:named() then
            attr.value = self:get_text(child):gsub("\"", "")
        end
    end

    return attr
end

-- 1206
---@param node TSNode
function Tag:get_el_data(node)
    if node:type() ~= "element" then return {} end

    local start_tag
    for child in node:iter_children() do
        local ctype = child:type()

        if ctype == "start_tag" or ctype == "self_closing_tag" then
            start_tag = child
            break
        end
    end

    if not start_tag then return {} end

    local tag, attrs = nil, {}
    for child in start_tag:iter_children() do
        local ntype = child:type()
        if ntype == "tag_name" then
            tag = self:get_text(child)
        elseif ntype == "attribute" then
            local attr = self:get_attr(child)
            attrs[attr.name] = attr.value
        end
    end

    return { tag = tag, attrs = attrs }
end

function Tag:parse_helper() --
    ---@param child TSNode
    for child in self.node:iter_children() do
        local ntype = child:type()

        if ntype == "text" then
            self:append(self:get_text(child))
        elseif ntype == "element" then
            self:append(self:from(child))
        elseif ntype == "entity" then
            local text = self:get_text(child)

            if text == "&lcnl;" then
                self:endl()
            elseif text == "&lcpad;" then
                self:endgrp()
            else
                self:append(utils.entity(text))
            end
        end
    end
end

-- 701
function Tag.trim(lines) --
    if not lines or vim.tbl_isempty(lines) then return {} end

    while not vim.tbl_isempty(lines) and lines[1]:content() == "" do
        table.remove(lines, 1)
    end

    while not vim.tbl_isempty(lines) and lines[#lines]:content() == "" do
        table.remove(lines)
    end

    return lines
end

local function req_tag(str) return require("leetcode-ui.group.tag." .. str) end

function Tag:contents()
    local items = Tag.super.contents(self)

    for _, value in ipairs(items) do
        value:replace(Tag.trim(value:contents()))
    end

    return items
end

---@param node TSNode
function Tag:from(node)
    local tbl = {
        pre = req_tag("pre"),
        ul = req_tag("list.ul"),
        ol = req_tag("list.ol"),
        li = req_tag("li"),
        img = req_tag("img"),
        a = req_tag("a"),
    }

    local tags = self.tags
    local el = self:get_el_data(node)

    table.insert(tags, self)
    local parsed = (tbl[el.tag] or Tag)(self.text, {}, node, tags)
    table.remove(tags)

    return parsed
end

---@param text string
---@param opts lc.ui.opts
---@param node TSNode
---@param tags lc.ui.Tag[]
function Tag:init(text, opts, node, tags) --
    self.text = text
    self.node = node
    self.tags = tags

    self.data = self:get_el_data(node)
    self.name = self.data.tag

    opts = vim.tbl_extend("force", {
        hl = utils.hl(self),
    }, opts or {})

    Tag.super.init(self, {}, opts)

    self:parse_helper()
end

---@type fun(text: string, opts: lc.ui.opts, node: TSNode, tags: lc.ui.Tag[]): lc.ui.Tag
local LeetTag = Tag

---@param text string
function Tag.static:parse(text) --
    local ok, parser = pcall(ts.get_string_parser, text, "html")
    assert(ok, parser)
    local root = parser:parse()[1]:root()

    return LeetTag(text, { spacing = 3, hl = "leetcode_normal" }, root, {})
end

return LeetTag