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

command! -nargs=0 T lua require'termwrapper'.new()

command! -nargs=* Tsend lua require'termwrapper'.send(<f-args>)

command! -nargs=0 TsendLine lua require'termwrapper'.send_line()

command! -nargs=0 TsendLineAdvance lua require'termwrapper'.send_line_advance()

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_termwrapper = 1
