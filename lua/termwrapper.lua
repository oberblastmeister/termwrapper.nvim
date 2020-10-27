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

  function custom_autocmd(event, vim_command, opts)
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
  vim.cmd('file ' .. self.filename)
  vim.b.term_title = self.filename
  terminals[self.number] = self
  custom_autocmd('TermClose', string.format('lua require("termwrapper").terminals[%s]:on_close()', self.number), {
    pat = self.filename,
    once = true,
  })
  if vim.g.termwrapper_autoinsert == 1 then
    vim.cmd [[startinsert]]
  end
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

function new()
  TermWrapper.new()
end

function setup()
  augroup('TermWrapper')
end

return {
  TermWrapper = TermWrapper,
  terminals = terminals,
  setup = setup,
  new = new,
}
