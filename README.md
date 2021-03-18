# Makefile Patterns

I was just figuring out some more advanced Gnu **make** tricks when
a couple of BSD users trying one of my projects told me they were
unable to build my project.  That shortcoming inspired me to rethink
my approach.  This project, then, is the place where I will record
my successful ideas so I can find them later.

I'm changing the organization of the README page, putting descriptions
of hopefully useful scripts at the top, and the summary of **make**
structures further down.  This reflects my progress having gone from
a makefile novice needing to establish the vocabulary for discussing
ideas, to working out more interesting solutions.

## Objectives

There are twin objectives with this project.  I want a reminder of
makefile basics when I return to writing them after a interval away.
I also want to explore methods for writing portable makefile scripts,
to support both Linux and BSD.

I'm finding some problems with BSD in some cases.  I may be able to
resolve some of them as I learn more.  I'm not sure how uniform are
BSD environments: I can kludge solutions, but they may not work on
different BSD installations.

## Makefile Scripts

- [make_need_ld_so.mk](make_need_ld_so.mk) uses the
  [shell assign](#variable-assignment) (!=) to determine if the
  user's runtime environment will search a given directory.

  This may not be necessary for BSD: FreeBSD seems to search
  `/usr/local/lib` by default.  **ldconfig** on BSD documents
  `/etc/ld.so.conf`, but FreeBSD, at least, does not have a
  `/etc/ld.so.conf` file.

- [make_db5.mk](make_db5.mk) looks under `/usr` for *db.h* and
  *libdb.so* to see if the header file and shared library files
  are compatible.

- [make_c_patterns.mk](make_c_patterns.mk) is a more complicated
  script, using targets and recipes to clone my
  [c_patterns repository](www.github.com/cjungmann/c_patterns.git)
  and create links to a subset of the contained files in the
  `src` project directory.


## Significant Concepts

### Rules

A make file consists of variable definitions and rules.

~~~make
# This is a rule template
target [target2 ...]: prerequisite [prerequisite2 ...]
       recipe
       recipe line 2
       ...
~~~

- **Target** is the object that must be created.  This is usually
  some sort of file, an object or an executable file, but it
  can be something else, too.

- **Prerequisite** is a file or other object that is the most
  recent version of its type.  If the prerequisite does not
  exist, there must be a rule that can provide it.

- **Recipe** is one or more steps that will be taken each time
  the rule is invoked.

#### Rules for Compiling and Linking

A *makefile* exists to make something, usually building some
application, program, or library from source files.  Let's say
the ultimate target is a program called **mp** that predicts
the phase of the moon for a given date.

~~~Makefile
TARGET = mp

${TARGET} : readdate.o calcphase.o useriface.o
    ${CC} -o ${TARGET} $^

%o: %c
    ${CC} -o $@ $<
~~~

The only required part of a rule is the *target*, though a
naked target is not much use.  Most makefiles will include
a rule that consists of a *target* and one or more *prerequisites*:

~~~Makefile
all: ${TARGET}
~~~

A rule may also be a *target* and a *recipe* without any
*prerequisites*.

One example of this kind of rule is a rule designed by be
called with make on the command line.  The *clean* rule,
for example, might delete all the generated files to start
a build from scratch.

~~~Makefile
# The .PHONY rule should precede a rule whose target is not a file.
.PHONY: clean
clean:
   rm -f ${TARGET}
   rm -f *.o
~~~

A rule without prerequisites can also be invoked because it is
a prerequisite of another rule.

An example of a prerequisite-invoked rule is a directory with
downloaded material.  Add the directory name as a prerequisite,
then make a rule whose target is the directory name.  The recipe
could create the directory directly or as a git clone.

~~~Makefile
all: c_patterns $(TARGET}

c_patterns:
   git clone --depth=1 http://github.com/cjungmann/c_patterns.git/
~~~

## Makefile *install* Target

Installing software makes changes to the user's computer, some of
which may not be easily reversed.  I think it's appropriate to adopt
a physician's motto to "do no harm," so the recipe lines of your
*install* target must be carefully considered.


### /usr/local/lib

The default place for installing software is under `/usr/local`,
`/usr/local/lib` for libraries, `/usr/local/bin` for programs, etc.
On some distributions, the runtime linker does not, by default,
search `/usr/local/lib` for shared libraries, resulting in runtime
errors when the library is not found.

One solution is to install your software in `/usr/lib` and `/usr/bin`,
but those directories are meant for system software.  The other possible
solution is to add `/usr/local/lib` to the library search path.  Running
`ldconfig /usr/local/lib` works only until the next boot.  A persistent
remedy is to fix `/etc/ld.so.conf`, have having **make** do it violates
the spirit of doing no harm.  As I write this, having just had [StackExchange][1] discussion on this topic, I am going to detect the missing path and
write a warning with remedy advice if it's not found.

If you're interested, my makefile had previously run the following to
fix the problem.  I won't have it do that anymore, but will instead add
this to a message:

~~~sh
echo "/usr/local/lib" > /etc/ld.so.conf.d/usr_local_lib.conf
~~~


[1]: https://stackoverflow.com/questions/66639901/what-are-acceptable-changes-to-make-to-a-users-computer-during-make-install "StackExchange discussion"



## Makefile Variables

Effective makefile design makes extensive use of variables.
There are *automatic variables* who have context values,
*predefined variables* used by implicit rules and can be changed
according to a developer's objectives.

### Variable Types

- **Automatic variables** are used in recipes to retrieve
  specifics about the target and the prerequisites.

  `info make -n "automatic variables"`

- **Predefined variables** are always available, and can be
  changed by setting them.  For example, CFLAGS is used by the
  default C compiler rule.  Many have default values, many are
  empty, but all can be changed to accomplish developer goals.
  
  `info make -n "implicit variables"`

### Variable Assignment

Refer to `info make -n "automatic variables"

The assignment operator determines how and *when* the variable
is set.  The offline reference is `info make -n Setting`

- `=` Recursively expanded (lazy) assign.  Functions and variables
  are evaluated when used.  This is the only operator that can
  be have different values at different points in the script.

- `::=` (or GNU-only `:=`)  Immediately expanded assign.
  The variable is set with the variable value and function
  results when the assignment is executed.

- `?=` Conditional assign.  Only make the assignment if the
  variable is not already set.  The PREFIX variable is the
  obvious example, where you would only want to set it if the
  user had not already set it.

- `!=` Shell assign.  Treats the r-value as an invocation of a
  shell command, assigning the result to the variable.

### Computed Variable Names

I just discovered this and plan to explore this feature
as a back-door function.  This is nested $(..) structures.

`info make -n "computed names"

## Testing for Installed Libraries: [make_confirm_libs.mk](make_confirm_libs.mk)

I don't necessarily recommend using this anymore, primarily
because I can't make it portable for BSD.  And finally, it's
not really that useful as the linker also reports on missing
libraries.

That said, I think that the contents of this file can still be
useful as examples of solutions using makefile code.

The problem with **find** is that you can't truely suppress the
errors caused by forbidden directories, thus you can't depend on
the exit value **find** returns, and the error messages may cause
worry.

I solve these two issues by sending error messages to oblivion
with `2>/dev/null`, and following **find** with **grep** which
provides a useful exit value if **find** was successful with
errors.







## Useful Links

As I play with ideas, especially ones that don't work, I often look
at online resources.  The following list are pages that seemed helpful
to me when I first encountered them.  If the past is a guide, they may
become decreasingly, and eventually, embarrassingly unimportant as I
gain knowledge and experience.

- [Makefiles, Best Practices](http://danyspin97.org/blog/makefiles-best-practices/)
  This is a nice short list of fundamental hints with explanations.

- [Practical Makefiles, by example](http://nuclear.mutantstargoat.com/articles/make/)
  includes more details and information that I may use in  the future,
  even if not yet, like compiler-generated dependency files for optimising
  builds.

