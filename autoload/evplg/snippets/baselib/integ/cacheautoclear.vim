
if exists('g:loaded_evplg_snippets_baselib_autoload_baselib_integ_cacheautoclear') || &cp
	finish
endif
let g:loaded_evplg_snippets_baselib_autoload_baselib_integ_cacheautoclear = 1

" force "compatibility" mode {{{
if &cp | set nocp | endif
" set standard compatibility options ("Vim" standard)
let s:cpo_save=&cpo
set cpo&vim
" }}}


" restore old "compatibility" options {{{
let &cpo=s:cpo_save
unlet s:cpo_save
" }}}

" vim600: set filetype=vim fileformat=unix:
" vim: set noexpandtab:
" vi: set autoindent tabstop=4 shiftwidth=4:
