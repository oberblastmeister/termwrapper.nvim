local utils = require('termwrapper/utils')
local TermWrapper = utils.TermWrapper

local M = {}

function M.setup()
  utils.augroup('TermWrapper')
  utils.custom_autocmd('TermClose', [[startinsert]])
end

function M.new()
  TermWrapper.new()
end

function M.close()
  TermWrapper.on_close()
end

return M
