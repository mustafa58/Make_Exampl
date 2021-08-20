CC=gcc
CFLAGS=-g -Wall
DEPDIR=obj/.deps
DEPFLAGS=-MT $@ -MMD -MP -MF $(DEPDIR)/$*.d
rwildcard=$(foreach d,$(wildcard $1*), $(call rwildcard,$d/,$2) $(filter $(subst *,%,$2),$d))
dirsunder=$(foreach d,$(wildcard $1*/), $d $(call dirsunder,$d))
SRC=$(strip $(call rwildcard, src, *.c)) # Catches files for under src, at any depth
OBJ=$(patsubst src/%.c, obj/%.o, $(SRC)) # Be carefull about variable deferred expansion
BULDIR=$(subst src,obj, $(call dirsunder, src))
BIN=bin/main

all: $(BIN)

release: CFLAGS=-Wall -O2 -DNDEBUG
release: clean
release: $(BIN)

clean:
	rm -r bin/* obj/* obj/.deps
$(BIN): $(DEPDIR) $(BULDIR) $(OBJ)
	$(CC) $(CFLAGS) $(OBJ) -o $@

# Delete the built-in rules for building object files from .c files
$(OBJ): obj/%.o: src/%.c
# Define a rule to build object files based on .c or dependency files by making the associated dependency file
# a prerequisite of the target.  Make the DEPDIR an order only prerequisite of the target, so it will be created when needed, meaning
# the targets won't get rebuilt when the timestamp on DEPDIR changes
# See https://www.gnu.org/software/make/manual/html_node/Prerequisite-Types.html for order only prerequesites overview.
$(OBJ): obj/%.o: src/%.c $(DEPDIR)/%.d | $(DEPDIR)
	$(CC) $(CFLAGS) $(DEPFLAGS) -c $< -o $@

# Create the DEPDIR and directories under it; if they don't exist
$(DEPDIR):
	@mkdir -p $(subst src,$(DEPDIR), $(call dirsunder, src))
$(BULDIR):
	@mkdir -p $(BULDIR)
# Use pattern rules to build a list of DEPFILES
DEPFILES := $(SRC:src/%.c=$(DEPDIR)/%.d)#same as $(patsubst src/%.c, $(DEPDIR)/%.d, $(SRC))
# Mention each of the dependency files as a target, so make won't fail if the file doesn't exist
$(DEPFILES):

include $(wildcard $(DEPDIR)/*.d)
