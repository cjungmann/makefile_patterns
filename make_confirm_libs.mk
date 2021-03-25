# USAGE:
# 1. The default rule (all: ...) must precede including this file.
# 2. Before including this file, set variable FC_LIBS to the list of library names.
# 3. The variable FC_LINKER_LIBS will be defined containing the library link options.
#    Add this variable to the options list on your link step.  (See Makefile).

# Note the use of lazy-assignments to create function-like variables that are
# prefixed with FUNC_.  They can be used in a recipe for context-specific output.


FUNC_FINDLIB_ERR = "@echo \"The \\\"${LIBNAME}\\\" library is not installed.\"; echo \"Use your package manager to install it\"; echo \"then run \\\"make\\\" again.\"; echo; exit 1"
FUNC_FINDLIB_OK = "@echo \"Availability of required library \\\"${LIBNAME}\\\" confirmed.\""

FUNC_FINDLIB = find /usr -name lib${LIBNAME}.so 2>/dev/null | grep lib/lib${LIBNAME} | wc -l

# The variable, RESULT_FINDLIB, should be previously set using FUNC_FINDLIB:
FUNC_CHECK = if [ ${RESULT_FINDLIB} -eq 0 ]; then echo ${FUNC_FINDLIB_ERR}; else echo ${FUNC_FINDLIB_OK}; fi

# Make error message if no libraries specified (empty variable otherwise).
FC_LIBS_MISSING != w=$$(echo ${FC_LIBS} | wc -w); if [ $$w -eq 0 ]; then echo "@echo FC_LIBS contains no library names.  Libraries will not be checked or included."; fi

# unconditionally invoke variable, but it only contains
# a message if no libraries are specified in FC_LIBS.
Confirm_Libraries: ${FC_LIBS}
	${FC_LIBS_MISSING}

${FC_LIBS}:
	$(eval LIBNAME != echo "$@" )
	$(eval RESULT_FINDLIB != ${FUNC_FINDLIB} )
	$(eval ACTION != ${FUNC_CHECK} )
	${ACTION}

# The including makefile can append this value to the LDLIBS variable:
FC_LINKER_LIBS != echo ${FC_LIBS} | sed -E 's/([^[:space:]]+)/-l\1/g'
