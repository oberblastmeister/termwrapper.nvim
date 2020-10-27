local TermWrapper = {}
TermWrapper.__index = TermWrapper

local terminals = 0

local function dec_terminals()
  terminals = terminals - 1
end

function TermWrapper.new()
  local self = setmetatable({}, TermWrapper)
  vim.cmd [[terminal]]
  self.filename = api.nvim_buf_get_name(0) .. ';termwrapper' .. terminals
  self.number = terminals
  self.job_id = vim.b.terminal_job_id
  vim.cmd('file ' .. self.filename)
  inc_terminals()
  return self
end

function TermWrapper:clear()
  self:send("clear")
end

function TermWrapper:send(command)
  vim.fn.jobsend(self.job_id, command .. '\n')
end

function TermWrapper.on_close()
  -- sending a any random key will close the terminal
  api.nvim_feedkeys('q', 'n', true)
  dec_terminals()
end

return TermWrapper
