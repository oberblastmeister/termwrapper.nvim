local api = vim.api

local TermWrapper = {}
TermWrapper.__index = TermWrapper

local terminals = {}

local function augroup(name)
  vim.cmd("augroup " .. name)
  vim.cmd("autocmd!")
  vim.cmd("augroup END")
end

local custom_autocmd
do
  local default_autocmd_opts = {
    pat = "term://*;termwrapper*",
    once = false,
    nested = false,
    group = "TermWrapper",
  }

  custom_autocmd = function(event, vim_command, opts)
    opts = vim.tbl_extend("keep", opts or {}, default_autocmd_opts)
    local command = "autocmd"
    if opts.group then command = command .. " " .. opts.group end
    command = command .. " " .. event .. " " .. opts.pat
    if opts.once then command = command .. " ++once" end
    if opts.nested then command = command .. " ++nested" end
    command = command .. " " .. vim_command
    vim.cmd(command)
  end
end


function TermWrapper.new()
  local self = setmetatable({}, TermWrapper)
  vim.cmd [[terminal]]
  self.number = vim.tbl_count(terminals) + 1
  self.filename = api.nvim_buf_get_name(0) .. ';termwrapper' .. self.number
  self.channel = vim.bo.channel
  vim.cmd('keepalt file ' .. self.filename)
  vim.b.term_title = self.filename
  custom_autocmd('TermClose', string.format('lua require("termwrapper").terminals[%s]:on_close()', self.number), {
    pat = self.filename,
    once = true,
  })
  if vim.g.termwrapper_autoinsert == 1 then
    vim.cmd [[startinsert]]
  end
  terminals[self.number] = self
  return self
end

function TermWrapper:clear()
  self:send("clear")
end

function TermWrapper:send(command)
  vim.fn.chansend(self.channel, command .. '\n')
end

function TermWrapper:on_close()
  if vim.g.termwrapper_autoclose == 1 then
    api.nvim_feedkeys('q', 'n', true)
  end

  -- remove the terminal from the global list
  terminals[self.number] = nil
end

function TermWrapper:close()
  self.send('exit')
end

local function new()
  TermWrapper.new()
end

local function send(...)
  local opts = {...}
  local command = opts[1]

  for idx = 2, vim.tbl_count(opts) do
    local terminal_num = opts[idx]
    local terminal = terminals[tonumber(terminal_num)];
    terminal:send(command)
  end

  if opts[2] == nil then
    if terminals[1] ~= nil then
      terminals[1]:send(command)
    end
  end
end

-- terminal id is optional, will send to 1 by default
local function send_line(terminal_id)
  local line = api.nvim_get_current_line()
  send(line, terminal_id)
end

local function send_line_advance(terminal_id)
  send_line()
  local linenr = api.nvim_win_get_cursor(0)[1]
  local next_line = api.nvim_buf_get_lines(0, linenr, linenr + 1, false)[1]
  vim.cmd('echom ' .. next_line)

  -- make sure we are not at the end of the file
  if next_line ~= nil then
    print('yes')
    return
  end

  if next_line:match('%S') == nil then
    vim.cmd [[normal! 2+]]
  else
    vim.cmd [[normal! +]]
  end
end

local function setup()
  augroup('TermWrapper')
end

return {
  TermWrapper = TermWrapper,
  terminals = terminals,
  setup = setup,
  send = send,
  send_line = send_line,
  send_line_advance = send_line_advance,
  new = new,
}
