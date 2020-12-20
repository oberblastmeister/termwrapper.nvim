local vim = vim
local api = vim.api
local utils = require("termwrapper/utils")

local TermWrapper = {}
TermWrapper.__index = TermWrapper

-- all of the termwrappers that have been created
local TermWrapperList = {}

--- private fields
-- do
--   local previous_action_number = 1
--   local termwrappers

--   function TermWrapperList:save(termwrapper)
--     termwrappers[termwrapper.number] = termwrapper
--   end

--   function TermWrapperList:save_previous_action(number)
--     previous_action_number = number
--   end

--   function TermWrapperList:previous_action()
--     return previous_action_number
--   end

--   function TermWrapperList:iter()
--     return pairs(termwrappers)
--   end
-- end

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
  utils.debug("Current bufnr: ", current_bufnr)
  for _, termwrapper in pairs(TermWrapperList) do
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
  return TermWrapperList[number]
end

--- runs the split command for this termwrapper
function TermWrapper:split()
  vim.cmd(self.split_command)
end

-- creates a new termwrapper in the current window
function TermWrapper.new(number, split_command)
  local self = setmetatable({}, TermWrapper)

  if number ~= nil and TermWrapper.get(number) ~= nil then
    print('hello')
    utils.warning("There is already a termwrapper for the given number: ", number)
    return
  end

  self.split_command = split_command or TermWrapperConfig.default_window_command
  self:split()
  vim.cmd [[terminal]]

  self:set_options()

  -- the number of the terminal, starts from 1
  self.number = number or vim.tbl_count(TermWrapperList) + 1

  -- only used when toggling to restore window view
  self.width = api.nvim_win_get_width(0)
  self.height = api.nvim_win_get_height(0)

  -- the channel, used to send commands to it
  self.channel = vim.bo.channel

  -- the buffer number
  self.bufnr = api.nvim_get_current_buf()

  -- change the filename initialy
  self:set_name(self:get_default_name())

  -- autoclose the termwrapper (no process exited)
  -- fix when user changes the filename
  utils.custom_autocmd('TermClose', string.format('lua require("termwrapper").TermWrapper.get(%s):on_close()', self.number), {
    pat = self.filename,
    once = true,
  })

  local wins = api.nvim_list_wins()
  self.fullscreen = #wins == 1

  on_new()
  vim.cmd [[set filetype=termwrapper]]

  TermWrapperList[self.number] = self

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
  utils.debug('Sending to channnel: ', self.channel)
  vim.fn.chansend(self.channel, command .. '\n')
end

-- sets then name of the termwrapper (keeps alternate file)
function TermWrapper:set_name(name)
  local command = string.format("keepalt call nvim_buf_set_name(%s, \"%s\")", self.bufnr, name)
  self.filename = name
  vim.cmd(command)
end

function TermWrapper:get_default_name()
  return api.nvim_buf_get_name(0) .. ';termwrapper' .. self.number
end

--- sets the correct window options
function TermWrapper:set_options()
  vim.wo.winfixheight = true
end

function TermWrapper:on_close()
  if TermWrapperConfig.autoclose then
    -- non-blocking feedkeys
    api.nvim_input('<Esc>')
  end

  -- remove the terminal from the global list
  TermWrapperList[self.number] = nil
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
  utils.debug("Winid: ", winid)

  if winid == nil then
    utils.warning("The buffer does not exist or there is no such window.")
    return
  end

  if self.split_command:find("vsplit") then
    api.nvim_win_set_width(winid, self.width)
  else
    api.nvim_win_set_height(winid, self.height)
  end
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
  local winid = self:get_winid()
  if winid == nil then
    utils.info('opening')

    vim.wo.winfixheight = true

    if self.fullscreen then
      vim.cmd(self.bufnr .. 'buffer')
    else
      vim.cmd(self.split_command)
      vim.cmd(self.bufnr .. 'buffer')
      self:resize()
    end
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
  return utils.get_first_existing(TermWrapperList)
end

function TermWrapper.get_or_first_existing(number)
  local termwrapper = TermWrapper.get(number)
  -- if there is not termwrapper for the number, get the first existing termwrapper
  if termwrapper == nil then
    utils.info("Getting the first existing termwrapper")
    termwrapper = TermWrapper.get_first_existing()
  end
  return termwrapper
end

return {
  TermWrapperList = TermWrapperList,
  TermWrapper = TermWrapper,
}
-- return TermWrapper
