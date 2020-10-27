if exists('g:loaded_termwrapper') | finish | endif

let s:save_cpo = &cpo
set cpo&vim

if ! exists('g:termwrapper_autoinsert')
  let g:termwrapper_autoinsert = 1
endif

if ! exists('g:termwrapper_autoclose')
  let g:termwrapper_autoclose = 1
end

lua require'termwrapper'.setup()

command! -nargs=0 Tnew lua require'termwrapper'.new()

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_termwrapper = 1
