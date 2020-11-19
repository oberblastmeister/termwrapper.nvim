local vim = vim
local api = vim.api
local utils = require("termwrapper/utils")

local TermWrapper = {}
TermWrapper.__index = TermWrapper

local termwrappers = {}

local function get_current_termwrapper()
  local current_bufnr = api.nvim_get_current_buf()
  for _, termwrapper in ipairs(termwrappers) do
    if termwrapper.bufnr == current_bufnr then
      return termwrapper
    end
  end
end

-- gets the termwrapper specified by the number. If the number is zero or nil, will get the current termwrapper
local function get_termwrapper(number)
  if number == nil or number == 0 then
    return get_current_termwrapper()
  end
  return termwrappers[number]
end

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


-- creates a new termwrapper in the current window
function TermWrapper.new()
  local self = setmetatable({}, TermWrapper)
  vim.cmd [[terminal]]
  self.number = vim.tbl_count(termwrappers) + 1
  self.filename = api.nvim_buf_get_name(0) .. ';termwrapper' .. self.number
  self.channel = vim.bo.channel
  self.bufnr = api.nvim_get_current_buf()
  vim.cmd('keepalt file ' .. self.filename)
  vim.b.term_title = self.filename
  custom_autocmd('TermClose', string.format('lua require("termwrapper").get_termwrapper(%s):on_close()', self.number), {
    pat = self.filename,
    once = true,
  })
  if vim.g.termwrapper_open_autoinsert == 1 then
    vim.cmd [[startinsert]]
  end
  vim.cmd [[set filetype=termwrapper]]
  termwrappers[self.number] = self
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
  if vim.g.termwrapper_autoclose == 1 then
    api.nvim_feedkeys('q', 'n', true)
  end

  -- remove the terminal from the global list
  termwrappers[self.number] = nil
end

function TermWrapper:exit()
  self.send('exit')
end

local function custom_open_window()
  vim.cmd(vim.g.termwrapper_default_window_command)
end

function TermWrapper:toggle()
  local winid = vim.fn.bufwinid(self.bufnr)
  if winid == -1 then
    custom_open_window()
    self:enter()
    if vim.g.termwrapper_toggle_auto_insert == 1 then
      vim.cmd [[startinsert]]
    end
  else
    api.nvim_win_close(winid, false)
  end
end

function TermWrapper:enter()
  vim.cmd(self.bufnr .. 'buffer')
end

local function get_first_existing(table)
  for _, item in ipairs(table) do return item end
end

-- gets the first existing termwrapper
local function get_first_existing_termwrapper()
  return get_first_existing(termwrappers)
end

-- Toggles the termwrapper or creates a new one if there are know termwrappers.
-- The number arg can be provided to toggle a specific termwrapper but if it is not provided, this will toggle number 1 by default.
-- If the number is not found, will toggle the first termwrapper found
local function toggle(number)
  if number == nil then
    number = 1
  end
  local termwrapper = get_termwrapper(number)
  -- if there is not termwrapper for the number, get the first existing termwrapper
  if termwrapper == nil then
    termwrapper = get_first_existing_termwrapper()
  end

  -- if there are no existing termwrappers anywhere, create a new one if the option is set
  if termwrapper == nil then
    if vim.g.termwrapper_open_new_toggle == 1 then
      custom_open_window()
      TermWrapper.new()
    else
      print('There are no termwrappers existing. Set g:termwrapper_open_new_toggle to open a new one when there is none in toggling.')
    end
  else
    termwrapper:toggle()
  end
end

local function new()
  TermWrapper.new()
end

local function send(...)
  local opts = vim.tbl_flatten {...}
  local command = opts[1]

  for idx = 2, vim.tbl_count(opts) do
    local terminal_num = opts[idx]
    local terminal = termwrappers[tonumber(terminal_num)];
    terminal:send(command)
  end

  if opts[2] == nil then
    if termwrappers[1] ~= nil then
      termwrappers[1]:send(command)
    end
  end
end

local function send_or_toggle(...)
  if termwrappers[1] == nil then
    toggle()
  end
  send(...)
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

local setup_config
do
  local default_config = {
    open_autoinsert = 1,
    toggle_autoinsert = 1,
    autoclose = 1,
    winenter_autoinsert = 0,
    default_window_command = "belowright 13split",
    open_new_toggle = 1,
    log = 0
  }

  setup_config = function(user_config)
    return vim.tbl_extend("keep", user_config, default_config)
  end
end

local function setup(user_config)
  setup_config(user_config)
  augroup('TermWrapper')
  if vim.g.termwrapper_winenter_autoinsert == 1 then
    custom_autocmd('WinEnter', 'startinsert')
  end
end

return {
  TermWrapper = TermWrapper,
  setup = setup,
  send = send,
  send_or_toggle = send_or_toggle,
  send_line = send_line,
  send_line_advance = send_line_advance,
  get_termwrapper = get_termwrapper,
  new = new,
  toggle = toggle,
}
