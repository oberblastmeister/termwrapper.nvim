local api = vim.api
local TermWrapper = require('')

local M = {}

local terminals = 0

function M.augroup(name)
  vim.cmd("augroup " .. name)
  vim.cmd("autocmd!")
  vim.cmd("augroup END")
end

do
  local default_autocmd_opts = {
    pat = "term://*;termwrapper*",
    once = false,
    nested = false,
    group = "TermWrapper",
  }

  function M.custom_autocmd(event, vim_command, opts)
    local opts = vim.tbl_extend("keep", opts or {}, default_autocmd_opts)
    local command = "autocmd"
    if opts.group then command = command .. " " .. opts.group end
    command = command .. " " .. event .. " " .. opts.pat
    if opts.once then command = command .. " ++once" end
    if opts.nested then command = command .. " ++nested" end
    command = command .. " " .. vim_command
    vim.cmd(command)
  end
end

local function inc_terminals()
  terminals = terminals + 1
end

local function dec_terminals()
  terminals = terminals - 1
end

function M.setup()
  M.augroup('TermWrapper')
  M.custom_autocmd('TermClose', [[lua require'termwrapper'.close()]])
  M.custom_autocmd('TermClose', [[startinsert]])
end

function M.new()
  vim.cmd [[terminal]]
  local filename = api.nvim_buf_get_name(0)
  filename = filename .. ';termwrapper' .. terminals
  vim.cmd('file ' .. filename)
  inc_terminals()
end

function M.close()
  -- sending a any random key will close the terminal
  api.nvim_feedkeys('q', 'n', true)
  dec_terminals()
end

return M
