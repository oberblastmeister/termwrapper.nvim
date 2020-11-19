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

return M
