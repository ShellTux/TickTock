MAKEFLAGS += --jobs=4 --output-sync=target

CC = clang++
CFLAGS  = -Wall -Wextra -Werror
CFLAGS += -Wno-error=unused-parameter
CFLAGS += -Wno-error=unused-variable
CFLAGS += -Wno-error=unused-but-set-variable
CFLAGS += -I"$$PWD/include/"
CFLAGS += -fPIC
FLAGS = -shared -pedantic
LINKS = 

SRCDIR = src
OBJDIR = obj
TESTDIR = tests
INCLUDEDIR = include
TARDIR = build

TARGET = $(TARDIR)/ticktock.so
TESTTARGET = $(TARDIR)/test

SOURCES  = $(shell find $(SRCDIR) \
	   -name "*.c" -o \
	   -name "*.cpp" -o \
	   -name "*.s" -o \
	   -name "*.asm" | tr '\n' ' ')
TESTSRCS := $(SOURCES) $(shell find $(TESTDIR) -type f \
	    -name '*.cpp' -o \
	    -name '*.c' -o \
	    -name '*.s' -o \
	    -name '*.asm' | tr '\n' ' ')

OBJECTS := $(SOURCES:%=$(OBJDIR)/%.o)
TESTOBJS := $(TESTSRCS:%=$(OBJDIR)/%.o)

HEADERS  = $(shell find $(INCLUDEDIR) \
	   -name "*.h" -o \
	   -name "*.hpp" \
	   | tr '\n' ' ')

.PHONY: all
all: $(TARGET)

debug-flags: CFLAGS += -g
debug-flags: clean $(TARGET)

debug: CFLAGS += -DDEBUG=1
debug: $(TARGET)

setup: .clangd pre-commit

.PHONY: .git/hooks/%
.git/hooks/%: scripts/%
	install --mode=755 $< $@

.PHONY: .clangd
.clangd:
	rm --force $@

	@echo Diagnostics: | tee --append $@
	@echo '  UnusedIncludes: Strict' | tee --append $@
	@echo '  MissingIncludes: Strict' | tee --append $@
	@echo CompileFlags: | tee --append $@
	@echo '  Add:' | tee --append $@

	@for flag in $(CFLAGS) ; do echo "    - $$flag" | tee --append $@ ; done

$(SRCDIR) $(OBJDIR) $(TARDIR) $(TESTDIR):
	mkdir --parents --verbose $@

.PHONY: clean
clean:
	@printf "Cleaning\n"
	rm -f $(TARGET)
	rm -r $(OBJDIR) || true
	rm -r $(VENV) || true

$(TARGET): $(OBJECTS) | $(TARDIR)
	@printf "\n\033[31m"
	@printf "########################\n"
	@printf "Building %s\n" $@
	@printf "########################\n"
	@printf "\033[0m\n"
	$(CC) $(FLAGS) $(CFLAGS) -o $@ $^ $(LINKS)

check:
	parallel --jobs 4 --group clang-tidy --quiet ::: $(SOURCES)

$(OBJDIR)/%.cpp.o: %.cpp $(HEADERS) | $(OBJDIR)
	@printf "\n\033[31m"
	@printf "########################\n"
	@printf "Building %s\n" $@
	@printf "########################\n"
	@printf "\033[0m\n"
	mkdir -p `dirname $@`
	$(CC) $(CFLAGS) -c -o $@ $<

.PHONY: test
test: $(TESTTARGET)
	GTEST_COLOR=1 ./$@ | diff-so-fancy

$(TESTTARGET): $(TESTOBJS) | $(TARDIR)
	@printf "\n\033[31m"
	@printf "########################\n"
	@printf "Running unit tests...\n"
	@printf "########################\n"
	@printf "\033[0m\n"
	strip --strip-symbol=main $(OBJECTS)
	$(CC) $(CFLAGS) -o $@ $^ $(LINKS)

.PHONY: format
format:
	$(eval FILES := $(SOURCES) $(TESTSRCS) $(HEADERS))
	clang-format --verbose -i $(FILES) 2>&1

.PHONY: watch
watch:
	@while true ;\
	do \
		clear ; \
		$(MAKE) $(TARGET) --no-print-directory; \
		inotifywait --quiet --event modify $(SOURCES) $(HEADERS); \
	done

.PHONY: watch-test
watch-test:
	@while true ;\
	do \
		clear ; \
		$(MAKE) test --no-print-directory; \
		inotifywait --quiet --event modify $(TESTSRCS) $(HEADERS); \
	done

.PHONY: PRINT-MACROS
PRINT-MACROS:
	@make -p MAKE-MACROS| grep -A1 "^# makefile" | grep -v "^#\|^--" | sort

