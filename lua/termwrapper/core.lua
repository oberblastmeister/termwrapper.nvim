local vim = vim
local api = vim.api
local utils = require("termwrapper/utils")

TermWrapper = {}
TermWrapper.__index = TermWrapper

-- all of the termwrappers that have been created
local termwrappers = {}

-- commands to execute when toggling
local function on_toggle()
  if TermWrapperConfig.toggle_autoinsert then
    utils.debug("Starting insert for toggle")
    vim.cmd [[startinsert]]
  end
end

-- things to execute on termwrapper new creation
local function on_new()
  if TermWrapperConfig.open_autoinsert then
    vim.cmd [[startinsert]]
  end
end


function TermWrapper.current()
  local current_bufnr = api.nvim_get_current_buf()
  for _, termwrapper in pairs(termwrappers) do
    utils.debug("Found termwrapper bufnr: ", termwrapper.bufnr)
    if termwrapper.bufnr == current_bufnr then
      utils.info("Got current termwrapper:")
      utils.dump_debug(termwrapper)
      return termwrapper
    end
  end
  utils.info("Failed to get current termwrapper")
end

-- gets the termwrapper specified by the number. If the number is zero or nil, will get the current termwrapper
function TermWrapper.get(number)
  if number == nil or number == 0 then
    utils.info("Getting current termwrapper")
    return TermWrapper.current()
  end
  return termwrappers[number]
end

-- creates a new termwrapper in the current window
function TermWrapper.new(number)
  local self = setmetatable({}, TermWrapper)
  vim.cmd [[terminal]]

  if TermWrapper.get(number) ~= nil then
    utils.error("There is already a termwrapper for the given number: ", number)
    return
  end

  self.number = number or vim.tbl_count(termwrappers) + 1
  self.filename = api.nvim_buf_get_name(0) .. ';termwrapper' .. self.number
  self.channel = vim.bo.channel
  self.bufnr = api.nvim_get_current_buf()
  vim.cmd('keepalt file ' .. self.filename)
  vim.b.term_title = self.filename
  utils.custom_autocmd('TermClose', string.format('lua require("termwrapper").TermWrapper.get(%s):on_close()', self.number), {
    pat = self.filename,
    once = true,
  })
  on_new()
  vim.cmd [[set filetype=termwrapper]]
  termwrappers[self.number] = self

  utils.debug("Created a new termwrapper:")
  utils.dump_debug(self)

  return self
end

-- convenience method to send clear to the termwrapper
function TermWrapper:clear()
  self:send("clear")
end

-- sends something to the termwrapper (adds newline at the end)
function TermWrapper:send(command)
  vim.fn.chansend(self.channel, command .. '\n')
end

-- sets then name of the termwrapper (keeps alternate file)
function TermWrapper:set_name(name)
  local command = string.format("keepalt call nvim_buf_set_name(%s, \"%s\")", self.bufnr, name)
  print(command)
  vim.cmd(command)
end

function TermWrapper:on_close()
  if TermWrapperConfig.autoclose then
    api.nvim_feedkeys('q', 'n', true)
  end

  -- remove the terminal from the global list
  termwrappers[self.number] = nil
end

function TermWrapper:exit()
  self.send('exit')
end

function TermWrapper:toggle()
  local winid = vim.fn.bufwinid(self.bufnr)
  if winid == -1 then
    vim.cmd(TermWrapperConfig.default_window_command)
    vim.cmd(self.bufnr .. 'buffer')
    on_toggle()
  else
    api.nvim_win_close(winid, false)
  end
end

function TermWrapper:enter()
  vim.cmd(self.bufnr .. 'buffer')
end

-- gets the first existing termwrapper
function TermWrapper.get_first_existing()
  return utils.get_first_existing(termwrappers)
end

function TermWrapper.get_or_first_existing(number)
  local termwrapper = TermWrapper.get(number)
  -- if there is not termwrapper for the number, get the first existing termwrapper
  if termwrapper == nil then
    termwrapper = TermWrapper.get_first_existing()
  end
  return termwrapper
end

return TermWrapper
