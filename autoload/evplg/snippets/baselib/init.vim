
if exists('g:evplg_snippets_baselib_autoload_baselib_init') || &cp
	finish
endif
let g:evplg_snippets_baselib_autoload_baselib_init = 1

" force "compatibility" mode {{{
if &cp | set nocp | endif
" set standard compatibility options ("Vim" standard)
let s:cpo_save=&cpo
set cpo&vim
" }}}

function! evplg#snippets#baselib#init#uninit_lazy( uninit_all_flag )
	try
		call evplg#snippets#baselib#scopecache#uninit_scopecache_lazy( a:uninit_all_flag )
	finally
		if ( a:uninit_all_flag )
			" NOTE: for now, we won't uninitialise
			" 'g:evplg_snippets_scopes_specdict', as that is usually populated
			" from the scripts that are "source"d/"runtime"d, and some of
			" those might fail to do anything when "source"d/"runtime"d a
			" second time.
			"? unlet! g:evplg_snippets_scopes_specdict g:evplg_snippets_scopes_procdict
			unlet! g:evplg_snippets_scopes_procdict
		endif
	endtry
endfunction

function! s:local_procdict_getentryforscope( scope )
	if ! has_key( g:evplg_snippets_scopes_procdict, a:scope )
		let g:evplg_snippets_scopes_procdict[ a:scope ] = {}
	endif
	return g:evplg_snippets_scopes_procdict[ a:scope ]
endfunction

function! evplg#snippets#baselib#init#init_lazy()
	try
		let l:needs_scope_initialisation = evplg#snippets#baselib#scopecache#init_scopecache_lazy()
		if ( ! l:needs_scope_initialisation )
			return
		endif

		" MAYBE: have a "changedtick"-sortof-based global definitions, which
		" can be manually reset (and thus its "changedtick" would be
		" increased, thus triggering refreshing from every buffer's snippets
		" when those are used).
		"
		if ( ! exists( 'g:evplg_snippets_scopes_specdict' ) )
			" TODO: implement registration?
			let g:evplg_snippets_scopes_specdict = {}
		endif
		if ( ! exists( 'g:evplg_snippets_scopes_procdict' ) )
			let g:evplg_snippets_scopes_procdict = {}
		endif

		" TODO: IDEA: make this 'if' unconditional
		" TODO: move the operations related to b:evplg_snippets_scopes_cachedict
		"  to the appropriate module
		" TODO: retrieve the key (currently in variable l:scope_cachedict_key)
		"  only when needed, and possibly remove code dependencies on knowing that
		"  value (just for l:scopes_list is bad enough for now)
		"
		" re-generate the entry in 'b:evplg_snippets_scopes_cachedict' if needed
		" prev: if ( ! has_key( b:evplg_snippets_scopes_cachedict, l:scope_cachedict_key ) )
		if !0
			let l:runtime_spec_pref = 'evplg/snippets/init/scopes/'
			" TODO: create a function (in another module?) to abstract the
			" calculation for the list of scopes to consider.
			"  IDEA: evplg#snippets#baselib#init#_get_scopes_list()
			"  (to which we'll add the 'all' here)
			let l:scopes_list = evlib#strset#AsList(
						\		evlib#strset#Add(
						\				evlib#strset#Create(
						\						split( b:evplg_snippets_current_cachedict_key, '\W' )
						\					),
						\				[ 'all' ]
						\			)
						\	)
			" echomsg 'DEBUG: l:scopes_list=' . string( l:scopes_list )
			for l:scope_now in l:scopes_list
				" prev: if ! has_key( g:evplg_snippets_scopes_procdict, l:scope_now )
				" prev: 	let g:evplg_snippets_scopes_procdict[ l:scope_now ] = {}
				" prev: endif
				" prev: let l:scope_procdict = g:evplg_snippets_scopes_procdict[ l:scope_now ]
				let l:scope_procdict = s:local_procdict_getentryforscope( l:scope_now )
				if ( ! get( l:scope_procdict, 'done_runtime', 0 ) )
					" do a 'runtime' on the appropriately named files:
					"  (something like: runtime! evplg/snippets/scopes/SCOPE{[-_]*,/*,}.vim)
					"
					" NOTE: no need to use 'evlib#compat#fnameescape()' on
					" some of the components (no including the ones containing
					" wildcards, as those would be unnecessarily (and wrongly)
					" escaped, too), as we know that each of those components
					" does not need escaping.
					let l:runtime_specs_now = join(
								\		map(
								\				[
								\					'',
								\					'[-_]*',
								\					'/*',
								\				],
								\				'printf(''%s%s%s.vim'', l:runtime_spec_pref, l:scope_now, v:val )'
								\			),
								\		' '
								\	)
					try
						" echomsg 'DEBUG: about to run runtime! ' . l:runtime_specs_now
						execute 'runtime! ' . l:runtime_specs_now
					catch
						echomsg 'ERROR: lazy_init(): caught exception sourcing script. exception=' . string( v:exception ) . '; location=' . string( v:throwpoint )
					finally
						" flag the "scope" as having been dealt with, even when
						" there was an error, so we avoid re-'runtime'-ing buggy
						" or unlucky scripts repeatedly.
						let l:scope_procdict[ 'done_runtime' ] = !0
					endtry
				endif
			endfor

			" prev: " now we make a new cache entry in b:evplg_snippets_scopes_cachedict,
			" prev: " so that the 'init_functions' elements can use the (TODO: implement)
			" prev: " functions that work on the current cache entry.
			" prev: let b:evplg_snippets_scopes_cachedict[ l:scope_cachedict_key ] = {}
			" prev: let b:evplg_snippets_current_cachedict_key = l:scope_cachedict_key

			" call the 'init_functions' registered by the runtime scripts in the
			" previous loop.
			" prev: " FIXME: re-add later: for l:scope_now in l:scopes_list
			" prev: for l:scope_now in [] " FIXME: code inside the 'for' disabled for now
			for l:scope_now in l:scopes_list
				" prev: " prev: " prev: if ! has_key( b:evplg_snippets_scopes_procdict, l:scope_now )
				" prev: " prev: " prev: 	let b:evplg_snippets_scopes_procdict[ l:scope_now ] = {}
				" prev: " prev: " prev: endif
				" prev: " prev: " prev: let l:scope_procdict = b:evplg_snippets_scopes_procdict[ l:scope_now ]
				" prev: let l:scope_procdict = g:evplg_snippets_scopes_procdict[ l:scope_now ]
				let l:scope_procdict = s:local_procdict_getentryforscope( l:scope_now )
				" prev: " prev: if ( ! get( l:scope_procdict, 'done_init_functions', 0 ) )
				" prev: " TODO: instead: if ( ! evplg#snippets#baselib#scopecache#get_cached_value( 'done_init_functions', 0 ) )
				" prev: if ( ! evplg#snippets#baselib#scopecache#get_cached_value( '*done_init_functions', 0 ) )
				if !0
					" TODO: implement a priority-based list of 'init_functions',
					" so that we can execute a final list with the priority being
					" the primary key, and the relative order of "scopes" as a
					" likely secondary order (or just define the order to be
					" arbitrary between entries with the same priority).
					"  IDEA: populate a list/dict/whatever with a priority, and
					"  have a loop later to iterate through those
					"   IDEA: have a priority-based collection (or a generically
					"   sorted collection) in 'evlib'.
					"   IDEA: or just add elements to a priority-keyed dict (where
					"   each element is a list), and then write the resulting list
					"   iterating in sorted key order.
					"    IDEA: this can still be in evlib...
					"     evlib#keyedmlist#Create()
					"     evlib#keyedmlist#Add(keyedmlist, key, val) " to be used by 'registration' functions
					"     evlib#keyedmlist#Extend(keyedmlist, srcdst, srctoadd) " to update the priority list for every scope in the loop
					"     evlib#keyedmlist#GetFlat(keyedmlist, ... ) " opt: sortfunction (see ':h sort()') -- to get the final list of functions/funcrefs to call, in priority order
					for l:buffer_init_func_orig in values( get( l:scope_procdict, 'init_functions', {} ) )
						unlet! l:Buffer_init_func
						let l:Buffer_init_func = l:buffer_init_func_orig
						unlet l:buffer_init_func_orig
						try
							call call( l:Buffer_init_func, [ l:scope_now ] )
						catch
							echomsg 'ERROR: lazy_init(): caught exception executing initialisation function '
										\	. string( l:Buffer_init_func )
										\	'. exception=' . string( v:exception ) . '; location=' . string( v:throwpoint )
						endtry
					endfor
					" prev: " prev: let l:scope_procdict[ 'done_init_functions' ] = !0
					" prev: call evplg#snippets#baselib#scopecache#set_cached_value( '*done_init_functions', !0 )
				endif
			endfor
			"? let l:specdict_now = l:scope_specdict[ l:scope_now ]
			"? if ! has_key( l:scope_specdict, l:scope_now ) | continue | endif
		endif
	catch
		call evplg#snippets#baselib#init#uninit_lazy( 0 )
		echoerr 'exception caught: ' . string( v:exception ) . '; location=' . string( l:throwpoint )
	endtry
	" TODO: return value?
endfunction

let s:_local_initfunction_uniqueid = 0

function! evplg#snippets#baselib#init#initfunction_register( scope, func )
	let l:scope_procdict = s:local_procdict_getentryforscope( a:scope )
	if ( ! has_key( l:scope_procdict, 'init_functions' ) )
		let l:scope_procdict[ 'init_functions' ] = {}
	endif

	" TODO: detect overflow somehow
	let s:_local_initfunction_uniqueid += 1

	let l:initfunc_id = s:_local_initfunction_uniqueid
	let l:scope_procdict[ 'init_functions' ][ l:initfunc_id ] = a:func
	return l:initfunc_id
endfunction

function! evplg#snippets#baselib#init#initfunction_unregister( scope, func_reg_id )
	if ( ! has_key( g:evplg_snippets_scopes_procdict, a:scope ) )
		return 0
	endif
	let l:scope_procdict_initfunctions = get( s:local_procdict_getentryforscope( a:scope ), 'init_functions', {} )
	if ( ! has_key( l:scope_procdict_initfunctions, a:func_reg_id ) )
		return 0
	endif
	unlet l:scope_procdict_initfunctions[ a:func_reg_id ]
	return !0
endfunction

" restore old "compatibility" options {{{
let &cpo=s:cpo_save
unlet s:cpo_save
" }}}

" vim600: set filetype=vim fileformat=unix:
" vim: set noexpandtab:
" vi: set autoindent tabstop=4 shiftwidth=4:
