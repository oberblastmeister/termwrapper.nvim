local vim = vim
local api = vim.api
local utils = require("termwrapper/utils")
local TermWrapper = require("termwrapper/core")

local M = {}

M.TermWrapper = TermWrapper

local function custom_open_window()
  vim.cmd(TermWrapperConfig.default_window_command)
end

-- Toggles the termwrapper or creates a new one if there are know termwrappers.
-- The number arg can be provided to toggle a specific termwrapper but if it is not provided, this will toggle number 1 by default.
-- If the number is not found, will toggle the first termwrapper found
do
  -- Both functions rely on previous toggle if number is not given.
  -- 1 for the start
  local previous_toggle

  local function number_or_default(number)
    -- if no number is given, set it to the previous toggle
    utils.info("In number_or_default, previous toggle was ", previous_toggle)
    if number == nil then
      number = previous_toggle
    end
    
    -- or one if no previous toggle
    if number == nil then
      number = 1
    end
    
    return number
  end

  -- Toggle the termwrapper of the number or trys to get the first existing termwrapper.
  -- Fails if there are no termwrappers existing.
  -- TODO: add detecting the command to this
  function M.toggle_or_first(number)
    number = number_or_default(number)
    local termwrapper = TermWrapper.get_or_first_existing(number)

    -- set the previous toggle
    previous_toggle = termwrapper.number
    utils.info("The previous toggle was set to: ", previous_toggle)

    -- if there are no existing termwrappers anywhere, create a new one if the option is set
    if termwrapper == nil then
      print('There are no termwrapper existing.')
    else
      termwrapper:toggle()
    end
  end

  -- Like the previous function except will create a new one if the number does not exist
  -- TODO: add detecting the command to this
  function M.toggle_or_new(number, command)
    number = number_or_default(number)
    utils.info("number of default was ", number)
    local termwrapper = TermWrapper.get(number)

    -- if the termwrapper is new, create a new one
    if termwrapper == nil then
      utils.info("Creating a new termwrapper: ", number)
      termwrapper = TermWrapper.new(number, command)
    else
      termwrapper:toggle()
    end

    previous_toggle = termwrapper.number
    utils.info("The previous toggle was set to: ", previous_toggle)
  end
end

local function get_count()
  local count = api.nvim_get_vvar("count")
  if count == 0 then
    count = nil
  end
  return count
end

function M.toggle_count()
  local count = get_count()
  utils.debug("The count was: ", count)
  M.toggle_or_new(count)
end

function M.close_current()
  TermWrapper.get(0):toggle()
end

-- new helper method that opens window
function M.new(number)
  custom_open_window()
  TermWrapper.new(number)
end

function M.send(cmd, number)
  local termwrapper = TermWrapper.get(number) or TermWrapper.new(number)
  termwrapper:send(cmd)
end
-- function M.send(...)
--   local opts = vim.tbl_flatten {...}
--   local command = opts[1]

--   for idx = 2, vim.tbl_count(opts) do
--     local terminal_num = opts[idx]
--     local termwrapper = TermWrapper.get(tonumber(terminal_num))
--     termwrapper:send(command)
--   end

--   if opts[2] == nil then
--     if termwrappers[1] ~= nil then
--       termwrappers[1]:send(command)
--     end
--   end
-- end

function M.send_or_toggle(...)
  local number = number_or_default()
  local termwrapper = TermWrapper.get(number)
  if termwrappers[1] == nil then
    toggle()
  end
  send(...)
end

-- terminal id is optional, will send to 1 by default
function M.send_line(terminal_id)
  local line = api.nvim_get_current_line()
  send(line, terminal_id)
end

function M.send_line_advance(terminal_id)
  M.send_line()
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

function M.setup(user_config)
  -- global variable TermWrapperConfig
  TermWrapperConfig = require"termwrapper/config".setup(user_config)

  utils.info("Starting logging for termwrapper")

  utils.debug("TermWrapperConfig:")
  utils.dump_debug(TermWrapperConfig)

  utils.augroup('TermWrapper')

  if TermWrapperConfig.termwrapper_winenter_autoinsert then
    utils.custom_autocmd('FileType', 'startinsert')
  end
end

return M
