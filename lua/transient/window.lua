-- in charge of displaying transient state

local M = {}

-- setup
M.ns = vim.api.nvim_create_namespace('transient')
M.bufnr = vim.api.nvim_create_buf(false, true)
M.win_lines = vim.api.nvim_get_option('lines') - vim.api.nvim_get_option('cmdheight') - 2
M.win_cols = vim.api.nvim_get_option('columns') - 4
-- assume winid is kept after closed
local win_config = {
    relative = 'editor',
    row = 2,
    col = 2,
    width = M.win_cols,
    height = M.win_lines,
    style = 'minimal',
    border = {{" ", "NormalFloat"}}
}

function M.open_win()
    M.winid = vim.api.nvim_open_win(M.bufnr, false, win_config)
    vim.api.nvim_win_set_option(M.winid, 'winblend', 0)
end

function M.close_win()
    vim.api.nvim_win_close(M.winid, true)
end

function M.display_option_value(opt, opt_type)
    if not opt_type or opt_type == 'toggle' then
        if opt == true then
            return 'on', 'StatusLine'
        else
            return 'off', 'StatusLineNC'
        end
    elseif opt_type == 'input' then
        if not opt or opt == '' then
            return 'nothing', 'StatusLineNC'
        else
            return opt, 'StatusLine'
        end
    elseif type(opt_type) == 'table' then
        return tostring(opt_type[opt]), 'StatusLine'
    end
    return 'unknown', 'ErrorMsg'
end

-- (cur_keys, [Sections]) where Section = (header, type, [Options]) where
-- Option = (key, description, type, value)
function M.update_buf(state)
    local lines = {}
    local header_lines = {}
    local key_locations = {}
    local description_locations = {}
    -- value_locations can have different highlight groups, so store tuples of
    -- { hlgroup, line, startcol, endcol } which can directly be unpacked into
    -- nvim_buf_add_highlight
    local value_locations = {}
    local greyed_lines = {}
    for _, section in ipairs(state.sections) do
        local header = section.header
        table.insert(header_lines, #lines)
        table.insert(lines, header)
        local type = section.type
        for _, option in ipairs(section.options) do
            local linenr = #lines
            local key = option.key
            local is_candidate = vim.startswith(key, state.current_key_sequence)
            if not is_candidate then
                table.insert(greyed_lines, linenr)
            end
            local description = option.description
            local option_type = option.option_type
            local line = key .. ' ' .. description
            -- using length will not work on unicode, use strdisplaywidth
            if is_candidate then
                table.insert(key_locations, {linenr, 0, #key})
                table.insert(description_locations, {linenr, #key + 1, #description + #key + 1})
            end
            if type == "infix" then
                local value, hlgroup = M.display_option_value(option.value, option_type)
                line = key .. ' ' .. description .. ' ' .. value
                if is_candidate then
                    table.insert(value_locations, { hlgroup, linenr, #description + #key + 2, #value + #description + #key + 2})
                end
            end
            table.insert(lines, line)
            ::continue::
        end
    end
    vim.api.nvim_buf_set_lines(M.bufnr, 0, -1, false, lines)
    for _, line in ipairs(header_lines) do
        vim.api.nvim_buf_add_highlight(M.bufnr, M.ns, 'Directory', line, 0, -1)
    end
    for _, line in ipairs(greyed_lines) do
        vim.api.nvim_buf_add_highlight(M.bufnr, M.ns, 'Comment', line, 0, -1)
    end
    for _, pos in ipairs(key_locations) do
        vim.api.nvim_buf_add_highlight(M.bufnr, M.ns, 'NvimRegister', unpack(pos))
    end
    for _, pos in ipairs(description_locations) do
        vim.api.nvim_buf_add_highlight(M.bufnr, M.ns, 'NormalFloat', unpack(pos))
    end
    for _, pos in ipairs(value_locations) do
        vim.api.nvim_buf_add_highlight(M.bufnr, M.ns, unpack(pos))
    end
    vim.cmd('redraw')
end

return M
