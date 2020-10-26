local api = vim.api

local M = {}

M.terminals = 0

local function augroup(name)
  vim.cmd("augroup " .. name)
  vim.cmd("autocmd!")
  vim.cmd("augroup END")
end

local function inc_terminals()
  M.terminals = M.terminals + 1
end

local function dec_terminals()
  M.terminals = M.terminals - 1
end

function M.setup()
  augroup('Termwrapper')
  vim.cmd [[autocmd Termwrapper TermClose term://*;termwrapper* lua require'termwrapper'.close()]]
end

function M.new()
  vim.cmd [[terminal]]
  local filename = api.nvim_buf_get_name(0)
  filename = filename .. ';termwrapper' .. M.terminals
  vim.cmd('file ' .. filename)
  inc_terminals()
end

function M.close()
  api.nvim_feedkeys('q', 'n', true)
  dec_terminals()
end

return M
