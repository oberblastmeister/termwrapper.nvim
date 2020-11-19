if exists('g:loaded_termwrapper') | finish | endif

let s:save_cpo = &cpo
set cpo&vim

command! -nargs=0 T lua require'termwrapper'.new()

command! -nargs=* Tsend lua require'termwrapper'.send(<f-args>)

command! -nargs=* TsendOrToggle lua require'termwrapper'.send_or_toggle(<f-args>)

command! -nargs=0 TsendLine lua require'termwrapper'.send_line()

command! -nargs=0 TsendLineAdvance lua require'termwrapper'.send_line_advance()

command! -nargs=* Ttoggle lua require'termwrapper'.toggle(<f-args>)

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_termwrapper = 1
