
if exists('g:loaded_evplg_snippets_baselib_plugin_evplg_snippets_baselib_vim') || &cp
	finish
endif
let g:loaded_evplg_snippets_baselib_plugin_evplg_snippets_baselib_vim = 1

" force "compatibility" mode {{{
if &cp | set nocp | endif
" set standard compatibility options ("Vim" standard)
let s:cpo_save=&cpo
set cpo&vim
" }}}

command! -nargs=0  -bang -bar EVSnippetsCacheClear call evplg#snippets#baselib#init#uninit_lazy( <bang>0 )

" NOTE: defined here to use a function in an 'autoload'-ed module to avoid
" loading that module until the command is executed.
command! -nargs=* -bang -bar EVSnippetsCacheAutoClear
			\	call evplg#snippets#baselib#integ#cacheautoclear#cmdhelper_addfilespecs( <bang>0, <f-args> )

function! s:local_snippetdirs_getsuffixes()
	let l:plugin_snipmate_loaded = ( exists( ':SnipMateLoadScope' ) == 2 )
	let l:plugin_ultisnips_loaded = ( exists( ':UltiSnipsEdit' ) == 2 )

	" make sure we do nothing if none of the appopriate plugins are not currently installed/loaded.
	if ( !( l:plugin_ultisnips_loaded || l:plugin_snipmate_loaded ) )
		return []
	endif

	let l:dirs_suff = []
	for [ l:cond_now, l:dirs_now ] in [
				\		[
				\			( l:plugin_snipmate_loaded || l:plugin_ultisnips_loaded ),
				\			[
				\				'snipmate-compat',
				\			],
				\		],
				\		[
				\			l:plugin_snipmate_loaded,
				\			[
				\				'snipmate',
				\			],
				\		],
				\		[
				\			l:plugin_ultisnips_loaded,
				\			[
				\				'ultisnips',
				\			],
				\		],
				\	]
		if ( ! l:cond_now ) | continue | endif
		let l:dirs_suff += l:dirs_now
	endfor

	return l:dirs_suff
endfunction

" TODO: refactor to (new module) evlib#pathlist#StringListEscapedToPathListExpanded() // call with &runtimepath
" TODO: create inverse function: evlib#pathlist#PathListExpandedToStringListEscaped()
function! s:local_getpathlistexpanded( pathlist )
	" IDEA: replace '\,' inside the source string with a value that does not
	" occurr (IDEA: have a list of "nearly impossible" values in a 's:'
	" variable)
	" IDEA: use expand() on each element, so that we have "proper" element values
	" IDEA: then replace that string with the original value:
	"  IDEA: every time we do a substitution, enter that value in a dictionary
	"  to then use to restore the original values.
	" FIXME: for now, we won't consider any paths with ',' in them
	return split( a:pathlist, ',' )
endfunction

" TODO: make this more general, and expose it in evplg#*, instead of this plugin
function! s:local_readd_snippetdirs()
	" done: " TODO: work out which directories to add (IDEA: get the code from the
	" done: " 'coll.simple' plugin script)
	" done: " FIXME: for now, we'll just use the 'snipmate-compat' one
	" prev: let l:snippetdirs_suff_list = [ 'snipmate-compat' ]
	let l:snippetdirs_suff_list = s:local_snippetdirs_getsuffixes()
	if empty( l:snippetdirs_suff_list )
		return
	endif

	let l:snippetdirs_elem_regex_search = '\v(/snippetdirs/[^/]+)/?$'
	let l:snippetdirs_elem_regex_replace = '\1'
	let l:dirlist_remove_trailingslash_search = '\v([^/])/$'
	let l:dirlist_remove_trailingslash_replace = '\1'
	" normalise list to get rid of the trailing '/', if that is present.
	" prev: \				'fnamemodify( v:val, ":p" ), ' .
	let l:runtimepath_dirs_all_list = map(
				\		s:local_getpathlistexpanded( &runtimepath ),
				\		'substitute( ' .
				\				'v:val, ' .
				\				'l:dirlist_remove_trailingslash_search, ' .
				\				'l:dirlist_remove_trailingslash_replace, ' .
				\				'"" ' .
				\			')'
				\	)
	"-? let l:runtimepath_dirs_snippetdirs_current_list = map(
	"-? 			\		copy( l:runtimepath_dirs_all_list ),
	"-? 			\		'substitute( v:val, l:snippetdirs_elem_regex_search, ' .
	"-? 			\				'l:snippetdirs_elem_regex_replace, "" )'
	"-? 			\	)
	"-? " prev: let l:runtimepath_dirs_snippetdirs_current_dict = {}
	"-? " prev: for l:dir_now in l:runtimepath_dirs_snippetdirs_current_list
	"-? " prev: 	let l:runtimepath_dirs_snippetdirs_current_dict[ l:dir_now ] = 1
	"-? " prev: endfor
	"-? let l:runtimepath_dirs_snippetdirs_current_strset =
	"-? 			\	evlib#strset#Create( l:runtimepath_dirs_snippetdirs_current_list )
	"-? let l:runtimepath_dirs_candidateparents_list = filter(
	"-? 			\		copy( l:runtimepath_dirs_snippetdirs_current_list ),
	"-? 			\		'! evlib#strset#HasElement( l:runtimepath_dirs_snippetdirs_current_strset, v:val )'
	"-? 			\	)
	" prev: \		'match( v:val, l:snippetdirs_elem_regex_search ) < 0'
	let l:runtimepath_dirs_candidateparents_list = filter(
				\		copy( l:runtimepath_dirs_all_list ),
				\		'v:val !~# l:snippetdirs_elem_regex_search'
				\	)
	let l:runtimepath_dirs_all_strset = evlib#strset#Create( l:runtimepath_dirs_all_list )
	" TODO: update comments below, as the logic has now been implemented.
	" done: use l:runtimepath_dirs_candidateparents_list as an input for a
	" glob function to get existing directories? or just use
	" evlib#rtpath#ExtendRuntimePath() with the correct flag so that only
	" existing directories get added?
	"  NOTE: maybe not evlib#rtpath#ExtendRuntimePath(), as that adds elements
	"  to the beginning and end, with the '/after' directory, etc., and it's
	"  not that customisable yet.
	" process directories and "suffixes", giving priority to the directory
	" order, so the 'runtimepath' directory list has the (arguably
	" predictably) most influence on the order in which results are
	" gathered/concatenated.
	let l:snippetdirs = []
	for l:dir_now in l:runtimepath_dirs_candidateparents_list
		for l:suff_now in l:snippetdirs_suff_list
			" prev: let l:snippetdirs += split( glob( printf('%s/snippetdirs/%s', l:dir_now, l:suff_now ) ), "\n" )
			let l:dir_full_now = printf( '%s/snippetdirs/%s', l:dir_now, l:suff_now )
			if evlib#strset#HasElement( l:runtimepath_dirs_all_strset, l:dir_full_now )
						\	|| ( ! isdirectory( l:dir_full_now ) )
				continue
			endif
			call add( l:snippetdirs, l:dir_full_now )
		endfor
	endfor
	let l:snippetdirs_escaped = map(
				\		copy( l:snippetdirs ),
				\		'evlib#compat#fnameescape( v:val )'
				\	)
	let &runtimepath .= (
				\		( ( empty( &runtimepath ) || ( &runtimepath[ -1: ] == ',' ) ) ? '' : ',' ) .
				\		join( l:snippetdirs_escaped, ',' )
				\	)
endfunction

command -nargs=0 -bar EVSnippetsDirsAutoAdd call s:local_readd_snippetdirs()

" restore old "compatibility" options {{{
let &cpo=s:cpo_save
unlet s:cpo_save
" }}}

" vim600: set filetype=vim fileformat=unix:
" vim: set noexpandtab:
" vi: set autoindent tabstop=4 shiftwidth=4:
