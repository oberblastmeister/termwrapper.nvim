local vim = vim
local api = api

local M = {}

function M.info(...)
  if TermWrapperConfig.log >= 2 then
    vim.api.nvim_out_write(table.concat(vim.tbl_flatten {...}) .. "\n")
  end
end

function M.debug(...)
  if TermWrapperConfig.log >= 3 then
    vim.api.nvim_out_write(table.concat(vim.tbl_flatten {...}) .. "\n")
  end
end

function M.dump_info(...)
  if TermWrapperConfig.log >= 2 then
    local objects = vim.tbl_map(vim.inspect, {...})
    M.log(unpack(objects))
  end
end

function M.dump_debug(...)
  if TermWrapperConfig.log >= 3 then
    local objects = vim.tbl_map(vim.inspect, {...})
    M.debug(unpack(objects))
  end
end

function M.warning(...)
  if TermWrapperConfig.log >= 1 then
    vim.api.nvim_error_write(table.concat(vim.tbl_flatten {...}) .. "\n")
  end
end

function M.get_first_existing(table)
  for _, item in ipairs(table) do return item end
end

function M.augroup(name)
  vim.cmd("augroup " .. name)
  vim.cmd("autocmd!")
  vim.cmd("augroup END")
end

do
  local default_autocmd_opts = {
    pat = "term://*;termwrapper*",
    once = false,
    nested = false,
    group = "TermWrapper",
  }

  M.custom_autocmd = function(event, vim_command, opts)
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

function M.get_size(window)
  if window == nil then
    window = 0
  end
  local width = api.nvim_win_get_width(window)
  local height = api.nvim_win_get_height(window)
  return width, height
end

return M
