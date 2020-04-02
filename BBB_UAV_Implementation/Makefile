## Adopted and modified from http://www.cs.ru.nl/lab/xenomai/ 

mainfile = main_bbb

## Default Xenomai installation path
XENO ?= /usr/xenomai

XENOCONFIG=$(shell PATH=$(XENO):$(XENO)/bin:$(PATH) which xeno-config 2>/dev/null)

### Sanity check
ifeq ($(XENOCONFIG),)
all::
	@echo ">>> Invoke make like this: \"make XENO=/path/to/xeno-config\" <<<"
	@echo
endif


CC=$(shell $(XENOCONFIG) --cc)
CFLAGS=$(shell $(XENOCONFIG) --xeno-cflags) $(MY_CFLAGS)
LDFLAGS=$(shell $(XENOCONFIG) --xeno-ldflags) $(MY_LDFLAGS) -lnative


# This includes the library path of given Xenomai into the binary to make live
# easier for beginners if Xenomai's libs are not in any default search path.
LDFLAGS+=-Xlinker -rpath -Xlinker $(shell $(XENOCONFIG) --libdir)

#LDFLAGS+= -lrtdk
LDFLAGS+= -lxenomai

# for math library
LDFLAGS += -lm

src = $(wildcard *.c)
obj = $(src:.c=.o)

#LDFLAGS = -lGL -lglut -lpng -lz -lm

$(mainfile): $(obj)
	$(CC) -o $@ $^ $(LDFLAGS)
	#$(CC) $(CFLAGS) $? $(LDFLAGS) -lrtdk -o $@
	


.PHONY: clean
clean:
	rm -f $(obj) $(mainfile)