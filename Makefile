install:
	swift build -c release -Xswiftc -static-stdlib
	install .build/release/badonde /usr/local/bin
	echo "#!/bin/bash" > /usr/local/bin/burgh
	echo 'badonde burgh "$$@"' >> /usr/local/bin/burgh
	chmod +x /usr/local/bin/burgh

uninstall:
	rm -rf usr/local/bin/badonde
	rm -rf ~/.badonde
