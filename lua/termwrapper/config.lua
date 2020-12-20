local vim = vim

local setup
do
  local default_config = {
    open_autoinsert = true,
    toggle_autoinsert = true,
    autoclose = true,
    winenter_autoinsert = false,
    default_window_command = "botright 13split",
    open_new_toggle = true,
    log_level = 0,
  }

  setup = function(user_config)
    return vim.tbl_extend("keep", user_config, default_config)
  end
end

return {
  setup = setup,
}
