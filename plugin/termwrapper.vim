if exists('g:loaded_termwrapper') | finish | endif

let s:save_cpo = &cpo
set cpo&vim

command! -nargs=0 T lua require'termwrapper'.new()
command! -nargs=0 T lua require'termwrapper'.TermWrapper.new()

command! -nargs=* Tsend lua require'termwrapper'.send(<f-args>)

command! -nargs=* TsendOrToggle lua require'termwrapper'.send_or_toggle(<f-args>)

command! -nargs=0 TsendLine lua require'termwrapper'.send_line()

command! -nargs=0 TsendLineAdvance lua require'termwrapper'.send_line_advance()

command! -nargs=* Ttoggle lua require'termwrapper'.toggle_or_new(<f-args>)

nnoremap <expr> <Plug>(TermWrapperToggleNumber) "lua require'termwrapper'.get_termwrapper(" . v:count1 . '):toggle()'

function! TermWrapperStrategy(cmd)
  call v:lua.require('termwrapper').send(a:cmd, 1)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_termwrapper = 1
