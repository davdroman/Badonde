prefix ?= /usr/local
bindir = $(prefix)/bin

build:
	swift build --disable-sandbox -c release -Xswiftc -static-stdlib

install: build
	mkdir -p $(bindir)
	install .build/release/badonde $(bindir)
	install .build/release/burgh $(bindir)

test:
	swift test

uninstall:
	rm -rf $(bindir)/badonde
	rm -rf $(bindir)/burgh
	rm -rf ~/.badonde
