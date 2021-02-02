
if exists('g:evplg_snippets_baselib_autoload_baselib_valcommon') || &cp
	finish
endif
let g:evplg_snippets_baselib_autoload_baselib_valcommon = 1

" force "compatibility" mode {{{
if &cp | set nocp | endif
" set standard compatibility options ("Vim" standard)
let s:cpo_save=&cpo
set cpo&vim
" }}}

let s:escape_seq_dict = {
			\	'n': "\n",
			\ }

" TODO: MAYBE: create evplg#snippets#baselib#valcommon#init_lazy()
"  TODO: MAYBE: call: function! evplg#snippets#baselib#init#init_lazy() from this init functon

" MAYBE: also create others functions, which are more abstract: evplg#snippets#baselib#valcommon#getabstract('nl') ([n]ew [l]ine)

function! evplg#snippets#baselib#valcommon#getesc( id )
	" for now, we propagate errors (exceptions)
	return s:escape_seq_dict[ a:id ]
endfunction

" restore old "compatibility" options {{{
let &cpo=s:cpo_save
unlet s:cpo_save
" }}}

" vim600: set filetype=vim fileformat=unix:
" vim: set noexpandtab:
" vi: set autoindent tabstop=4 shiftwidth=4:
