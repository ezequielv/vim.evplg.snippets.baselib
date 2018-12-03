
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

" TODO: define functions to integrate with autocommands (use a global variable
" for the filespec(s) to install the autocmd(s) against)
"  IDEA: do not make the events configurable
"   TODO: ... but find out which events we should have autocmds for
"    (maybe: BufLeave)
" TODO: (in plugin/{for_this_plugin}.vim): define a command to invoke this
" function and optionally specify the override for the variable?
"  IDEA: do not use a variable directly, and leave that to the caller to
"  specify (so the command could use a variable as a default and, if unset, do
"  it for all files).
"  IDEA: allow to add filespecs to clear the cache automatically on
"   (but do not necessarily define a command to remove a filespec)
"  IDEA: have one to disable all autocmds for this
"
" IDEA: autocmd group: EVSnippetsIntegCacheAutoClear (or rename slightly so
"  that it does not match the command name below)
" IDEA: user cmd-friendly function: 
"  " MAYBE: just define this one where the command is being defined (possibly
"  " even a 's:' function)
"  function! evplg#snippets#baselib#integ#cmd_integrate_cacheautoclear( clear_prev_flag, ... )
"   " a:000 will have the files (if any)
"   call evplg#snippets#baselib#integ#cacheautoclear_addfilespecs( a:000, a:clear_prev_flag )
"  endfunction
"  " command (quick and dirty):
"  command -nargs=* -bang -bar EVSnippetsIntegCacheAutoClear func_above( <bang>0, <f-args> )
"  " IDEA #2: use a comma-separated list instead (and call using that list,
"  " which the function above will split() itself).
"  IDEA: low-level functions:
"   MAYBE: even use another submodule: 'evplg#snippets#baselib#integ#cacheautoclear#*()'
"  " #1: evplg#snippets#baselib#integ#cacheautoclear_addfilespecs( files_list [, clear_prev_flag] )
"  " #2: evplg#snippets#baselib#integ#cacheautoclear_clearfilespecs()

function! s:autocmd_cacheautoclear_do()
	if ( ! get( b:, 'evplg_snippets_cacheautoclear_enable', get( g:, 'evplg_snippets_cacheautoclear_enable', !0 ) ) )
		return
	endif
	call evplg#snippets#baselib#init#uninit_lazy( 0 )
endfunction

function! evplg#snippets#baselib#integ#cacheautoclear#addfilespecs( files_list, ... )
	let l:clear_prev_flag = ( ( a:0 > 0 ) ? a:1 : 0 )

	if l:clear_prev_flag || ( ! exists( '#EVSnippetsIntegCacheAutoClear' ) )
		call evplg#snippets#baselib#integ#cacheautoclear#clearfilespecs()
	endif

	let l:files_list = filter( copy( a:files_list ), '!empty(v:val)' )
	if ( ! empty( l:files_list ) )
		" prev: \	. ' call evplg#snippets#baselib#init#uninit_lazy(0)'
		execute 'autocmd EVSnippetsIntegCacheAutoClear BufLeave '
					\	. join( l:files_list, ',' )
					\	. ' call s:autocmd_cacheautoclear_do()'
		" ref: for ':command': call s:cmd_cacheautoclear( <bang>0, <f-args> )
	endif
endfunction

function! evplg#snippets#baselib#integ#cacheautoclear#clearfilespecs()
	augroup EVSnippetsIntegCacheAutoClear
		autocmd!
	augroup END
endfunction

" NOTE: command-invoked function renamed so that it can be invoked from a 'plugin/*.vim' file
" prev: function! s:cmd_addfilespecs( clear_prev_flag, ... )
function! evplg#snippets#baselib#integ#cacheautoclear#cmdhelper_addfilespecs( clear_prev_flag, ... )
	call evplg#snippets#baselib#integ#cacheautoclear#addfilespecs( a:000, a:clear_prev_flag )
endfunction

" restore old "compatibility" options {{{
let &cpo=s:cpo_save
unlet s:cpo_save
" }}}

" vim600: set filetype=vim fileformat=unix:
" vim: set noexpandtab:
" vi: set autoindent tabstop=4 shiftwidth=4:
