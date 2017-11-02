TARG=plan9.tar.gz
DISK=disk.raw

.PHONY: all

all: $(TARG)

$(TARG): $(DISK)
	tar -Sczf $@ $<
