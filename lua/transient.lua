local window = require('transient.window')
local util = require('transient.util')
local store = require('transient.store')

local M = {}

function M.loop(keymap)
    local state = vim.deepcopy(keymap.config)
    window.open_win()
    -- possible keys
    local pos = keymap.keys
    state.current_key_sequence = ''
    while true do
        window.update_buf(state)
        local key = util.getchar()
        state.current_key_sequence = state.current_key_sequence .. key
        pos = vim.tbl_filter(function(t)
            return vim.startswith(t.key, state.current_key_sequence)
        end, pos)
        if #pos == 0 then
            state.current_key_sequence = ''
            pos = keymap.keys
        elseif #pos == 1 then
            -- update
            local key_type = pos[1].type
            local i, j = unpack(pos[1].location)
            local opt = state.sections[i].options[j]
            if key_type == 'infix' then
                update_option(opt)
            else
                -- end
                window.close_win()
                opt.cb(state)
                break
            end
            state.current_key_sequence = ''
            pos = keymap.keys
        end
    end
end

function update_option(opt)
    if not opt.option_type or opt.option_type == 'toggle' then
        opt.value = opt.value ~= true
    elseif type(opt.option_type) == 'table' then
        if opt.value == #opt.option_type then
            opt.value = 1
        else
            opt.value = opt.value + 1
        end
    elseif opt.option_type == 'input' then
        opt.value = vim.fn.input(opt.prompt or 'transient> ')
    end
end

-- M.loop()

store.register_keymap({
    name = 'gcommit',
    sections = {
        {
            header = "Arguments",
            type = "infix",
            options = {
                {
                    key = "-a",
                    description = "Stage all modified and deleted files",
                },
                {
                    key = "-e",
                    description = "Allow empty commit",
                },
                {
                    key = "-v",
                    description = "show diff of changes to be commited",
                    value = true
                },
                {
                    key = "-n",
                    description = "disable hooks",
                },
                {
                    key = "-R",
                    description = "Claim ownership and reset author date",
                },
                {
                    key = "-A",
                    description = "override the author",
                    option_type = "input",
                    prompt = "--author=",
                },
                {
                    key = "-s",
                    description = "Add signed-off-by line",
                },
                {
                    key = "-C",
                    description = "reuse commit message",
                },
            }
        },
        {
            header = "Create",
            type = "suffix",
            options = {
                {
                    key = "c",
                    description = "commit",
                },
            }
        },
        {
            header = "Edit HEAD",
            type = "suffix",
            options = {
                {
                    key = "e",
                    description = "extend",
                },
                {
                    key = "w",
                    description = "reword",
                },
                {
                    key = "a",
                    description = "amend",
                },
            }
        },
        {
            header = "Edit",
            type = "suffix",
            options = {
                {
                    key = "f",
                    description = "fixup",
                    cb = function(state)
                        print(vim.inspect(state))
                    end
                },
                {
                    key = "s",
                    description = "squash",
                },
                {
                    key = "A",
                    description = "augment",
                },
            }
        }
    }
})

M.loop(store.get_keymap("gcommit"))
