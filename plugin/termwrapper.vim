if exists('g:loaded_termwrapper') | finish | endif

let s:save_cpo = &cpo
set cpo&vim

if ! exists('g:termwrapper_open_autoinsert')
  let g:termwrapper_open_autoinsert = 1
endif

if ! exists('g:termwrapper_toggle_auto_insert')
  let g:termwrapper_toggle_auto_insert = 1
endif

if ! exists('g:termwrapper_autoclose')
  let g:termwrapper_autoclose = 1
endif

if ! exists('g:termwrapper_winenter_autoinsert')
  let g:termwrapper_winenter_autoinsert = 0
endif

if ! exists('g:termwrapper_default_window_command')
  let g:termwrapper_default_window_command = 'belowright 13split'
endif

if ! exists('g:termwrapper_open_new_toggle')
  let g:termwrapper_open_new_toggle = 1
endif

lua require'termwrapper'.setup()

command! -nargs=0 T lua require'termwrapper'.new()

command! -nargs=* Tsend lua require'termwrapper'.send(<f-args>)

command! -nargs=0 TsendLine lua require'termwrapper'.send_line()

command! -nargs=0 TsendLineAdvance lua require'termwrapper'.send_line_advance()

command! -nargs=* Ttoggle lua require'termwrapper'.toggle(<f-args>)

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_termwrapper = 1
