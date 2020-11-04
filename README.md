# termwrapper.nvim

*termwrapper.nvim* is a wrapper for neovim's terminal features to make them more user friendly.

![image](https://user-images.githubusercontent.com/61095988/98062974-04e60380-1e1d-11eb-9836-2c3ff85f3c74.gif)

## Features

- toggle the terminal without losing any of the commands running in the terminal
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

## Commands

- `T`: create a new termwrapper
- `Ttoggle`: toggle the termwrapper
- `TsendLine`: send the current line to the termwrapper
- `Tsend`: send argument to the terminal
- `TsendLineAdvance`: same as `TsendLine` but goes to the next non-empty line in the file

## Options

- `g:termwrapper_open_autoinsert`: auto insert when opening a new termwrapper, default 1
- `g:termwrapper_toggle_auto_insert`: auto insert when toggling the termwrapper, default 1
- `g:termwrapper_autoclose`: auto close the termwrapper no (`[Process exited 0]` messages and then having to press a key to quit), default 1
- `g:termwrapper_winenter_autoinsert`: auto insert when entering the termwrapper window, default 0
- `g:termwrapper_default_window_command`: the default command to open a new window when toggling, default `belowright 13split`
