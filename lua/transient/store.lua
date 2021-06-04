local util = require('transient.util')

local M = {}

M.keymaps = {}

function M.register_keymap(keymap)
    local name = keymap.name
    if name == nil then
        util.err('No name provided for keymap')
        return
    end
    local info = {}
    for i, s in ipairs(keymap.sections) do
        for j, opt in ipairs(s.options) do
            -- housekeeping for default values
            if type(opt.option_type) == 'table' then
                opt.value = opt.value or 1
            end
            table.insert(info, {key = opt.key, type = s.type, location = {i, j}})
        end
    end
    M.keymaps[name] = { keys = info, config = keymap }
end

function M.get_keymap(name)
    return M.keymaps[name]
end

return M
