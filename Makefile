TARGET=the_app

# Use conditional assign in case user set custom PREFIX value
PREFIX ?= /usr/local
CFLAGS = -Wall -Werror -std=c99 -pedantic -m64 -ggdb
LDFLAGS =
LDLIBS = -lreadargs
SRC = src

# Default rule should come before all includes
# that might also include their own rules
all: Confirm_Libraries Confirm_DB5 Confirm_Readargs CP_PREPARE_SOURCES ${TARGET}

# Collect a list of modules from the source code files in the
# source directory.  If necessary, Use *grep*# between the *ls*
# and the *sed* commands to prune the list.
MODULES != ls -1 ${SRC}/*.c | sed 's/\.c/.o/g'

# Make sure CP_NAMES is set before including make_c_patterns.mk.
# make_c_patterns.mk uses the variable CP_NAMES to generate
# variables and for the include rules.  make_c_patterns.mk
# also defines CP_OBJECTS to be added to the prerequisites
# of the target rule.
CP_NAMES = get_keypress prompter columnize read_file_lines
include make_c_patterns.mk
MODULES += ${CP_OBJECTS}

# The library prerequisite list variable must be set before
# the that includes the prerequisite Confirm_Libraries
FC_LIBS = expat z
include make_confirm_libs.mk
LDLIBS += ${FC_LINKER_LIBS}

include make_db5.mk
CFLAGS += ${DB5_INC}
LDLIBS += ${DB5_LINK}

include make_static_readargs.mk
CFLAGS += ${RA_INC}
LDLIBS += ${RA_LINK}

# Remove duplicates:
MODULES != echo ${MODULES} | xargs -n1 | sort -u | xargs

# Note placement of CP_OBJECTS for make_c-patterns.mk and
# and placement of FC_LINKER_LIBS for make_confirm_libraries.mk
${TARGET}: ${MODULES}
	${CC} -o $@ ${MODULES} ${LDFLAGS} ${LDLIBS}

# Could skip as this is the same as default rule
%o: %c
	${CC} ${CFLAGS} -c -o $@ $<

include make_need_ld_so.mk

install:
	@# You would be installing software here.
	@# Include the following recipe if installing a library:
	${NEED_LD_SO_WARN1}
	${NEED_LD_SO_WARN2}

clean:
	@echo Removing generated files
	rm -f ${TARGET}
	rm -f src/*.o

full_clean:
	@echo Removing generated and downloaded files
	rm -f ${TARGET}
	rm -f src/*.o
	rm -f ${CP_SOURCES} ${CP_HEADERS}
	rm -rf c_patterns
