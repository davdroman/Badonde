prefix ?= /usr/local
bindir = $(prefix)/bin

install:
	swift build --disable-sandbox -c release -Xswiftc -static-stdlib
	install .build/release/badonde $(bindir)
	install .build/release/burgh $(bindir)

uninstall:
	rm -rf $(bindir)/badonde
	rm -rf $(bindir)/burgh
	rm -rf ~/.badonde
