# termwrapper.nvim

**note**: This plugin is in heavy development. Expect breaking changes. Also, this plugin support Neovim 0.5 only

*termwrapper.nvim* is a wrapper for neovim's terminal features to make them more user friendly.

![image](https://user-images.githubusercontent.com/61095988/98062974-04e60380-1e1d-11eb-9836-2c3ff85f3c74.gif)

## Features

- toggle the terminal without losing any of the commands running in the terminal
- toggling the terminal will keep the size
- send commands to terminal
- auto exit terminal when running `exit` (no `[Process exited 0]` messages and then having to press a key to quit)
- auto insert when creating the terminal
- good defaults
- written in lua

## Installation

### vim-plug

`Plug 'oberblastmeister/termwrapper.nvim'`

### packer.nvim

```lua
use 'oberblastmeister/termwrapper.nvim'
```

## Usage

Run:
```lua
require"termwrapper".setup {
    -- these are all of the defaults
    open_autoinsert = true, -- autoinsert when opening
    toggle_autoinsert = true, -- autoinsert when toggling
    autoclose = true, -- autoclose, (no [Process exited 0])
    winenter_autoinsert = false, -- autoinsert when entering the window
    default_window_command = "belowright 13split", -- the default window command to run when none is specified,
                                                   -- opens a window in the bottom
    open_new_toggle = true, -- open a new terminal if the toggle target does not exist
    log_level = 1, -- 1 = warning, 2 = info, 3 = debug
}
```

## Integrations

You can use termwrapper to run your tests with vim-test like this

```vim
let g:test#custom_strategies = {'termwrapper': function('TermWrapperStrategy')}
let g:test#strategy = 'termwrapper'
```

<!-- ## Commands -->

<!-- - `T`: create a new termwrapper -->
<!-- - `Ttoggle`: toggle the termwrapper -->
<!-- - `TsendLine`: send the current line to the termwrapper -->
<!-- - `Tsend`: send argument to the terminal -->
<!-- - `TsendLineAdvance`: same as `TsendLine` but goes to the next non-empty line in the file -->

<!-- ## Options -->

<!-- - `g:termwrapper_open_autoinsert`: auto insert when opening a new termwrapper, default 1 -->
<!-- - `g:termwrapper_toggle_auto_insert`: auto insert when toggling the termwrapper, default 1 -->
<!-- - `g:termwrapper_autoclose`: auto close the termwrapper no (`[Process exited 0]` messages and then having to press a key to quit), default 1 -->
<!-- - `g:termwrapper_winenter_autoinsert`: auto insert when entering the termwrapper window, default 0 -->
<!-- - `g:termwrapper_default_window_command`: the default command to open a new window when toggling, default `belowright 13split` -->
