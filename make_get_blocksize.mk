# Perhaps I'll never use this again, but just in case:
#
# Test by uncommenting last three lines of this file,
# then invoking the file with:
# make -f make_get_blocksize.mk

BLOCKSIZE != stat "." | grep -o IO\ Block:\ [[:digit:]]\\+ | grep -o [[:digit:]]\\+

# all: test
# test:
# 	@echo BLOCKSIZE is ${BLOCKSIZE}
