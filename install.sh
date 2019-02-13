#!/bin/bash

swift build -c release -Xswiftc -static-stdlib
cp -f .build/release/badonde /usr/local/bin/badonde
echo "#!/bin/bash" > /usr/local/bin/burgh
echo 'badonde burgh "$@"' >> /usr/local/bin/burgh
chmod +x /usr/local/bin/burgh
