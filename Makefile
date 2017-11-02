TARG=plan9.tar.gz
DISK=disk.raw

.PHONY: all clean

all: $(TARG)

$(TARG): $(DISK)
	tar -Sczf $@ $<

clean:
	rm -f $(TARG)
