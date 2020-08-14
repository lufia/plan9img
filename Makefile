TARG=plan9.tar.gz
DISK=disk.raw

.PHONY: all reset clean

all: $(TARG)

$(TARG): $(DISK)
	tar -Sczf $@ $<

reset:
	cp disk1-orig.raw disk1.raw

clean:
	rm -f $(TARG)
