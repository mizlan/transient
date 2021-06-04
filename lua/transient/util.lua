local M = {}

function M.t(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

-- taken from which-key
-- returns escape key on error
function M.getchar()
    local ok, n = pcall(vim.fn.getchar)

    -- bail out on keyboard interrupt
    if not ok then
        return M.t("<esc>")
    end

    local c = (type(n) == "number" and vim.fn.nr2char(n) or n)

    -- Fix < characters
    if c == "<" then
        c = "<lt>"
    end
    return c
end

return M
