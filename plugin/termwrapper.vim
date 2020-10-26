if exists('g:loaded_termwrapper') | finish | endif

let s:save_cpo = &cpo
set cpo&vim

lua require'termwrapper'.setup()

command! -nargs=0 Tnew lua require'termwrapper'.new()

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_termwrapper = 1
