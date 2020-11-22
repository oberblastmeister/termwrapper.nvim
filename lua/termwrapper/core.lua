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

  -- the number of the terminal, starts from 1
  self.number = number or vim.tbl_count(termwrappers) + 1

  -- the filename of the terminal, can be changed
  self.filename = api.nvim_buf_get_name(0) .. ';termwrapper' .. self.number

  -- the channel, used to send commands to it
  self.channel = vim.bo.channel

  -- the buffer number
  self.bufnr = api.nvim_get_current_buf()

  -- only used when toggling to restore window view
  self.width = api.nvim_win_get_width(0)
  self.height = api.nvim_win_get_height(0)

  -- change the filename initialy
  vim.cmd('keepalt file ' .. self.filename)
  vim.b.term_title = self.filename
  vim.wo.winfixheight = true

  -- autoclose the termwrapper (no process exited)
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
  vim.cmd(command)
end

function TermWrapper:on_close()
  if TermWrapperConfig.autoclose then
    -- non-blocking feedkeys
    api.nvim_input('<Esc>')
  end

  -- remove the terminal from the global list
  termwrappers[self.number] = nil
end

function TermWrapper:exit()
  self.send('exit')
end

-- will return nil if the buffer cannot be found of there is no such window
function TermWrapper:get_winid()
  local winid = vim.fn.bufwinid(self.bufnr)
  if winid == -1 then
    return nil
  else
    return winid
  end
end

-- resizes the termwrapper to the saved size
function TermWrapper:resize()
  local winid = self:get_winid()

  if winid == nil then
    utils.warning("The buffer does not exist or there is no such window.")
    return
  end

  api.nvim_win_set_height(winid, self.height)
  api.nvim_win_set_width(winid, self.width)
end

function TermWrapper:save_size()
  local winid = self:get_winid()

  if winid == nil then
    utils.warning("The buffer does not exist or there is no such window.")
    return
  end

  self.width = api.nvim_win_get_width(winid)
  self.height = api.nvim_win_get_height(winid)
end

function TermWrapper:toggle()
  local winid = vim.fn.bufwinid(self.bufnr)
  if winid == -1 then
    vim.wo.winfixheight = true
    vim.cmd(TermWrapperConfig.default_window_command)
    vim.cmd(self.bufnr .. 'buffer')
    self:resize()
    on_toggle()
  else
    self:save_size()
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
