local api = vim.api

local TermWrapper = {}
TermWrapper.__index = TermWrapper

local terminals = {}

local function get_termwrapper(number)
  return terminals[number]
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


function TermWrapper.new()
  local self = setmetatable({}, TermWrapper)
  vim.cmd [[terminal]]
  self.number = vim.tbl_count(terminals) + 1
  self.filename = api.nvim_buf_get_name(0) .. ';termwrapper' .. self.number
  self.channel = vim.bo.channel
  self.bufnr = vim.fn.bufnr(vim.fn.bufname())
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

function TermWrapper:exit()
  self.send('exit')
end

local function custom_open_window()
  vim.cmd(string.format('belowright %ssplit', vim.g.termwrapper_default_height))
end

function TermWrapper:toggle()
  local winid = vim.fn.bufwinid(self.bufnr)
  if winid == -1 then
    custom_open_window()
    vim.cmd(self.bufnr .. 'buffer')
    if vim.g.termwrapper_toggle_auto_insert == 1 then
      vim.cmd [[startinsert]]
    end
  else
    api.nvim_win_close(winid, false)
  end
end

local function get_first_existing(table)
  for _, item in ipairs(table) do return item end
end

local function toggle(number)
  if number == nil then
    number = 1
  end
  local termwrapper = get_termwrapper(number)
  -- if there is not termwrapper for the number, get the first existing termwrapper
  if termwrapper == nil then
    termwrapper = get_first_existing(terminals)
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
  if vim.g.termwrapper_winenter_autoinsert == 1 then
    custom_autocmd('WinEnter', 'startinsert')
  end
end

return {
  TermWrapper = TermWrapper,
  setup = setup,
  send = send,
  send_line = send_line,
  send_line_advance = send_line_advance,
  get_termwrapper = get_termwrapper,
  new = new,
  toggle = toggle,
}
