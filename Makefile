install:
	swift build -c release -Xswiftc -static-stdlib
	install .build/release/badonde /usr/local/bin
	install .build/release/burgh /usr/local/bin

uninstall:
	rm -rf usr/local/bin/badonde
	rm -rf usr/local/bin/burgh
	rm -rf ~/.badonde
