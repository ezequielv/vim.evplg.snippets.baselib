#- prev: !/usr/bin/env awk -f
#
# input awk variables
#  g_debug
#  g_outdir
#

function f_echo_stderr(			l_s ) {
	printf "%s%s\n", c_msgpref, l_s > "/dev/stderr"
}

function f_info(			l_s ) {
	f_echo_stderr( "[info] " l_s )
}

function f_error(			l_s, l_errorcode ) {
	if ( g_rc == 0 ) {
		if ( l_errorcode == 0 ) {
			l_errorcode = 1
		}
		g_rc = l_errorcode
	}

	f_echo_stderr( "ERROR: " l_s )
	return g_rc
}

function f_debug(			l_s ) {
	if ( !! g_debug ) {
		#? prev: v1: printf "%s%s: %s\n", c_msgpref, "DEBUG", l_s > "/dev/stderr"
		f_echo_stderr( "DEBUG: " l_s )
	}
}

BEGIN {
	# constants
	c_tab = "\t"
	c_msgpref = "[fix_snippets_indent_type] "
}

function f_finish_last_src_file(			l_rc, l_success, l_src_basename, l_out_filename, l_linenum_now ) {
	l_rc = 0
	l_success = !0

	if ( l_success && ( length( g_src_filename ) > 0 ) ) {
		l_rc = !0

		f_info( sprintf( " processed %d lines, containing:", g_src_lineproc_nlines ) )
		f_info( sprintf( "  snippets: total=%d, changed=%d", g_src_lineproc_nsnippets_total, g_src_lineproc_nsnippets_changed ) )
		f_info( sprintf( "  snippet content lines: total=%d, changed=%d", g_src_lineproc_snippetcontlines_total, g_src_lineproc_snippetcontlines_changed ) )

		if ( g_src_lineproc_haschanges ) {
			if ( length( g_outdir ) > 0 ) {
				l_src_basename = g_src_filename
				gsub( "^.*/", "", l_src_basename )
				if ( ( l_success = l_success && ( length( l_src_basename ) > 0 ) ) ) {
					l_out_filename = g_outdir "/" l_src_basename
				}
			} else {
				f_debug( "g_outdir is empty, writing to same pathname as the src" )
				l_out_filename = g_src_filename
			}

			if ( l_success ) {
				f_info( sprintf( " writing contents to %s . . .", l_out_filename ) )
				if ( g_src_lineproc_nlines > 0 ) {
					for ( l_linenum_now = 1; l_linenum_now <= g_src_lineproc_nlines; ++l_linenum_now ) {
						# MAYBE: use 'print' instead of 'printf', to allow users to change output format slightly
						#  (variable(s): ORS)
						# NOTE: all redirections use the same file descriptor, which is opened according to the redirection operator ('>' in this case).
						printf "%s\n", g_src_lineproc_lines[ l_linenum_now ] > l_out_filename
					}
					l_success = l_success && ( close( l_out_filename ) == 0 )
				} else {
					f_info( "  no lines were found for this input file. skipping." )
				}
			}
		} else {
			f_info( " file does not need modification. skipping writing phase." )
		}

		if ( ! l_success ) {
			f_error( sprintf( "processing file %s%s", g_src_filename, ( length( l_out_filename ) > 0 ) ? ( "(and/or writing to " l_out_filename ")" ) : "" ) )
		}
	}

	# (re)initialise variables used for (src) file processing

	g_src_filename = FILENAME

	# NOTE: the lines to be written out are stored in the array 'g_src_lineproc_lines', which is 1-based (first line is number 1).
	# therefore, the last line is always 'g_src_lineproc_lines[g_src_lineproc_nlines]' (for values of 'g_src_lineproc_nlines' > 0).
	g_src_lineproc_nlines = 0
	g_src_lineproc_haschanges = 0

	# flag: set if we are processing a 'snippet' construct
	#-? ... g_src_contents_snippetsbody_insnippet = 0
	g_src_lineproc_state = "state_line_other"
	# number of leading spaces detected (to be fixed, as only hardtabs are formally supported by snipmate)
	g_src_contents_snippetsbody_leadingspaces = 0

	g_src_lineproc_nsnippets_total = 0
	g_src_lineproc_nsnippets_changed = 0

	g_src_lineproc_snippetcurrent_changed = 0

	g_src_lineproc_snippetcontlines_total = 0
	g_src_lineproc_snippetcontlines_changed = 0

	return l_rc
}

# NOTE: use FNR (reset to 1 for each new file?) to detect filename change
# NOTE: defer to when there is a new input file (or END processing block when no errors have been found) to conditionally write out the changed file
# ref: mawk(1): "7. Builtin-variables"
( FNR == 1 ) {
	f_finish_last_src_file()
	f_info( "processing file " g_src_filename " . . ." )
}

{
	f_debug( "  line processing started" )

	r_line = $0
	f_debug( sprintf( "   line: {{%s}}", r_line ) )
	f_debug( sprintf( "   state on entry: %s", g_src_lineproc_state ) )

	r_line_fmtflag_snippetheader = ( r_line ~ /^snippet[ \t]/ )
	r_line_fmtflag_snippetcontents = ( r_line ~ /^[ \t]/ )
	# FIXME: support both empty lines and lines consisting only of whitespace as "potentially being part of a snippet contents":
	#  NOTE: both snipmate and ultisnips seem to support blank lines (even without any whitespace in them) as part of "snippet contents" if a proper "snippet contents" line follows:
	#   snippet some_snippet_...
	#   {tab}snippet_line_1
	#   {tab}snippet_line_2
	#   {blank_line}		<- this is part of the "snippet contents"
	#   {tab}snippet_line_3
	#   {blank_line}		<- this is *not* part of the "snippet contents"
	#   snippet another_snippet_...
	#
	#  IDEA: store the lines contents for those "maybe snippet contents" lines, or just how many of them there were (as only blank lines would fall into this category, I think),
	#   and process them when a certain state change happens:
	#    * -> "state_line_other": add them as they were (or just blank lines)
	#    * -> "state_snippet_content": add them as "\t" lines, so that both
	#          parsers take them properly (avoiding these "edge cases",
	#          making them more parser-friendly), and also (and more
	#          importantly) allowing the following lines to also being
	#          taken into consideration for re-indenting/validation, etc.
	#   NOTE: consider that the script can no longer blindly add lines to 'g_src_lineproc_lines' (near bottom of this script), but rather has to keep those "maybe content" lines in another array, or just conditionally update 'g_src_lineproc_lines' when 'g_src_lineproc_maybesnippcontents_nlines_last' is != 0 at that point (as it could have been set to zero after manually processing those "maybe content" lines before reaching that point).
	#   MAYBE: r_line_fmtflag_maybesnippcontents_blank = ( r_line ~ /^$/ )
	#           # MAYBE: (or just done below when determinig next state?): # ... && ( g_src_lineproc_state == "state_snippet_header" || g_src_lineproc_state == "state_snippet_content" )
	#   MAYBE: # initialisation # g_src_lineproc_maybesnippcontents_nlines_last = 0

	f_debug( sprintf( "   fmtflags: snippetheader=%d; snippetcontents=%d;", r_line_fmtflag_snippetheader, r_line_fmtflag_snippetcontents ) )
}

# done: add regular line processing (conditionally alter r_line)
#  IDEA: detect the first line inside a snippet that does not start with a hardtab, and set g_src_contents_snippetsbody_leadingspaces from that.
#   done: if the current "snippet content" line starts with a non-hardtab (spaces?), then replace the 'g_src_contents_snippetsbody_leadingspaces' leading spaces with a tab;
#    done: (if there are a multiple of the leading spaces?), replace multiples of the nleading spaces with tabs
#  done: update g_src_lineproc_nsnippets_total when a "start-of-snippet" line is found
# done: count the number of changed snippets inside each file
# done: count the number of "snippet content" lines: processed and changed (<= processed)

# done: conditionaly update g_src_lineproc_state
#  IDEA: (MAYBE: in the first block, just after setting r_line?) detect the format(s) or content type(s) the current line *could* comply with:
#   * r_line_fmtflag_snippetheader: snippet header (starts with "snippet" (TODO: check actual format in snipmate documentation))
#   * r_line_fmtflag_snippetcontents: snippet contents (starts with leading tab or spaces)
#  IDEA: then, allow state transitions depending on the content type(s)...
{
	if ( r_line_fmtflag_snippetheader ) {
		g_src_lineproc_state = "state_snippet_header"
	} else if ( ( g_src_lineproc_state == "state_snippet_header" ) && r_line_fmtflag_snippetcontents ) {
		g_src_lineproc_state = "state_snippet_content"
	} else if ( ( ! r_line_fmtflag_snippetheader ) && ( ! r_line_fmtflag_snippetcontents ) ) {
		g_src_lineproc_state = "state_line_other"
	}
	f_debug( "   state result: " g_src_lineproc_state )
}

# NOTE: processes state that can result in yet another transition:
#  for example, a "snippet content" line ("state_snippet_content") that has a
#  lower than expected leading spaces: this will transition the state to
#  "state_line_other".
( g_src_lineproc_state == "state_snippet_content" ) {
	r_line_fmtflag_snipcont_leading_spaces = ( r_line ~ /^[ ]/ )
	if ( r_line_fmtflag_snipcont_leading_spaces ) {
		if ( g_src_contents_snippetsbody_leadingspaces == 0 ) {
			g_src_contents_snippetsbody_regex_leadingspaces = r_line
			sub( "[^ ].*$", "", g_src_contents_snippetsbody_regex_leadingspaces )
			g_src_contents_snippetsbody_leadingspaces = length( g_src_contents_snippetsbody_regex_leadingspaces )
			if ( g_src_contents_snippetsbody_leadingspaces == 0 ) {
				# not_needed?: g_src_contents_snippetsbody_regex_leadingspaces = ""
				# TODO: something went wrong here: we should have a valid number, given the 'if' condition surrounding this sentence block.
				# TODO: f_error( ... )
			}
		} else if ( match( r_line, "^" g_src_contents_snippetsbody_regex_leadingspaces ) == 0 ) {
			# TODO: display a warning/info/debug message: "line has less leading spaces than expected for this snippet"
			g_src_lineproc_state = "state_line_other"
		}
	}
}

# react to g_src_lineproc_state: conditionally update r_line
{
	if ( g_src_lineproc_state == "state_line_other" ) {
		# leaves line unmodified
	} else if ( g_src_lineproc_state == "state_snippet_header" ) {
		# leaves line unmodified
	} else if ( g_src_lineproc_state == "state_snippet_content" ) {
		if ( r_line_fmtflag_snipcont_leading_spaces && ( g_src_contents_snippetsbody_leadingspaces > 0 ) ) {
			t_line_contentsuff = r_line
			t_line_leadingspaces = r_line
			sub( "^[ ]+", "", t_line_contentsuff )
			# TODO: de-duplicate this regex: put it in a constant
			sub( "[^ ].*$", "", t_line_leadingspaces )
			t_line_leadingtabs = ""
			# replace every instance of the "n" leading spaces with tabs.
			while ( match( t_line_leadingspaces, "^" g_src_contents_snippetsbody_regex_leadingspaces ) > 0 ) {
				t_line_leadingspaces = substr( t_line_leadingspaces, g_src_contents_snippetsbody_leadingspaces + 1 )
				t_line_leadingtabs = t_line_leadingtabs c_tab
			}
			r_line = t_line_leadingtabs t_line_contentsuff
		}
	} else {
		f_error( sprintf( "internal error: unhandled/unsupported lineproc state '%s'", g_src_lineproc_state ) )
	}
}

# commit to g_src_lineproc_lines array, update g_*_lineproc_* variables
{
	r_line_changed = ( $0 != r_line )
	if ( r_line_changed ) {
		f_debug( sprintf( "   line (changed): {{%s}}", r_line ) )
	}

	g_src_lineproc_haschanges = g_src_lineproc_haschanges || r_line_changed
	#g_src_lineproc_haschanges = !0 # FIXME: remove (testing)
	g_src_lineproc_lines[ ++g_src_lineproc_nlines ] = r_line

	if ( g_src_lineproc_state == "state_snippet_header" ) {
		++g_src_lineproc_nsnippets_total
		# reset variables for the current snippet (contents)
		g_src_lineproc_snippetcurrent_changed = 0
		# NOTE: for now, we allow each snippet body/contents to hav its own (unique) number of leading spaces.
		g_src_contents_snippetsbody_leadingspaces = 0
	} else if ( g_src_lineproc_state == "state_snippet_content" ) {
		++g_src_lineproc_snippetcontlines_total
		if ( r_line_changed ) {
			++g_src_lineproc_snippetcontlines_changed
			# count the current snippet as a "changed" one, but
			# only do that once per snippet.
			if ( ! g_src_lineproc_snippetcurrent_changed ) {
				g_src_lineproc_snippetcurrent_changed = !0
				++g_src_lineproc_nsnippets_changed
			}
		}
	}
}

END {
	f_debug( sprintf( "END block reached. values on entry: g_rc=%d;", g_rc ) )

	if ( g_rc == 0 ) {
		f_finish_last_src_file()
	}

	if ( g_rc == 0 ) {
		f_info( "exiting normally" )
	} else {
		f_info( "exiting with error code: " g_rc )
	}
	exit g_rc
}

