NASM=nasm
LD=ld
NASM_FLAGS=-f elf64 -F dwarf -g -I src/include/
LD_FLAGS=

SRCDIR=src
OBJDIR=obj

SOURCES=$(wildcard $(SRCDIR)/core/*.asm) \
        $(wildcard $(SRCDIR)/http/*.asm) \
        $(SRCDIR)/main.asm

OBJECTS=$(SOURCES:$(SRCDIR)/%.asm=$(OBJDIR)/%.o)

.PHONY: all clean

all: webserver

webserver: $(OBJECTS)
	$(LD) $(LD_FLAGS) -o $@ $^

$(OBJDIR)/%.o: $(SRCDIR)/%.asm
	@mkdir -p $(@D)
	$(NASM) $(NASM_FLAGS) -o $@ $<

clean:
	rm -rf $(OBJDIR) webserver


# ideally would build and run, then call curl from a different terminal
test:
	curl -v http://localhost:8270
