
if exists('g:evplg_snippets_baselib_autoload_baselib_scopecache') || &cp
	finish
endif
let g:evplg_snippets_baselib_autoload_baselib_scopecache = 1

" force "compatibility" mode {{{
if &cp | set nocp | endif
" set standard compatibility options ("Vim" standard)
let s:cpo_save=&cpo
set cpo&vim
" }}}

function! evplg#snippets#baselib#scopecache#_get_cachedict_key()
	" TODO: calculate this from the function to be created:
	"  IDEA: evplg#snippets#baselib#init#_get_scopes_list()
	"  and use something like 'join(list, ':')' to construct the key
	return printf( '%s:%s', &filetype, &syntax )
endfunction

function! evplg#snippets#baselib#scopecache#uninit_scopecache_lazy( uninit_all_flag )
	try
		let l:scope_cachedict_key = evplg#snippets#baselib#scopecache#_get_cachedict_key()

		if a:uninit_all_flag
			" rely on the 'finally' block below
			return
		endif
		if exists( 'b:evplg_snippets_scopes_cachedict' )
					\	&& has_key( b:evplg_snippets_scopes_cachedict, l:scope_cachedict_key )
			unlet b:evplg_snippets_scopes_cachedict[ l:scope_cachedict_key ]
		endif
	finally
		unlet! b:evplg_snippets_current_cachedict_key
		if a:uninit_all_flag
			unlet! b:evplg_snippets_scopes_cachedict
		endif
	endtry
endfunction

function! evplg#snippets#baselib#scopecache#init_scopecache_lazy()
	let l:success_flag = 0
	try
		let l:scope_cachedict_key = evplg#snippets#baselib#scopecache#_get_cachedict_key()
		if get( b:, 'evplg_snippets_current_cachedict_key', '' ) ==# l:scope_cachedict_key
			let l:success_flag = !0
			return 0
		endif
		unlet! b:evplg_snippets_current_cachedict_key

		" TODO: MAYBE: make this configurable (and default to "keep it clean")
		"  (and support both 'b:' and 'g:', so that the user can avoid
		"  expensive re-initialisations on edge cases (by setting the 'b:' for
		"  specific buffers to "do not do it" (0)))
		" TODO: call
		" evplg#snippets#baselib#scopecache#uninit_scopecache_lazy() with
		" either 0 or 1, so that the cache is kept as clean as possible when
		" switching between types, for example.
		"  NOTE: do this every time we are going to write a new entry in the
		"  cache, which is possibly every time we're executing this line.

		let l:has_initialised = 0
		if ( ! exists( 'b:evplg_snippets_scopes_cachedict' ) )
			let b:evplg_snippets_scopes_cachedict = {}
			let l:has_initialised = !0
		endif
		" update buffer "current scope cache" variables.
		if ( ! has_key( b:evplg_snippets_scopes_cachedict, l:scope_cachedict_key ) )
			" now we make a new cache entry in b:evplg_snippets_scopes_cachedict,
			" so that the 'init_functions' elements can use the (TODO: implement)
			" functions that work on the current cache entry.
			let b:evplg_snippets_scopes_cachedict[ l:scope_cachedict_key ] = {}
			let l:has_initialised = !0
		endif
		let b:evplg_snippets_current_cachedict_key = l:scope_cachedict_key
		" MAYBE: assign 'b:evplg_snippets_current_cachedict_dict' (to save all
		" those dictionary accesses below, and make code cleaner?), too?
		let l:success_flag = !0
		return l:has_initialised
	finally
		if ( ! l:success_flag )
			call evplg#snippets#baselib#scopecache#uninit_scopecache_lazy( 0 )
		endif
	endtry
endfunction

function! evplg#snippets#baselib#scopecache#has_cached_key( key )
	return has_key( b:evplg_snippets_scopes_cachedict[ b:evplg_snippets_current_cachedict_key ], a:key )
endfunction

function! evplg#snippets#baselib#scopecache#get_cached_value( key, defvalue )
	return get( b:evplg_snippets_scopes_cachedict[ b:evplg_snippets_current_cachedict_key ], a:key, a:defvalue )
endfunction

function! evplg#snippets#baselib#scopecache#set_cached_value( key, value )
	let b:evplg_snippets_scopes_cachedict[ b:evplg_snippets_current_cachedict_key ][ a:key ] = a:value
endfunction

function! evplg#snippets#baselib#scopecache#set_default_value( key, defvalue )
	if evplg#snippets#baselib#scopecache#has_cached_key( a:key )
		return 0
	endif
	call evplg#snippets#baselib#scopecache#set_default_value( a:key, a:defvalue )
	return !0
endfunction

" restore old "compatibility" options {{{
let &cpo=s:cpo_save
unlet s:cpo_save
" }}}

" vim600: set filetype=vim fileformat=unix:
" vim: set noexpandtab:
" vi: set autoindent tabstop=4 shiftwidth=4:
