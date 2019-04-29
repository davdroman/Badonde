prefix ?= /usr/local
bindir = $(prefix)/bin

build:
	swift build --disable-sandbox -c release

install: build
	mkdir -p $(bindir)
	install .build/release/badonde $(bindir)

test:
	swift test

uninstall:
	rm -rf $(bindir)/badonde
	rm -rf ~/.badonde
