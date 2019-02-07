#!/bin/bash

swift build -c release -Xswiftc -static-stdlib
cp -f .build/release/badonde /usr/local/bin/badonde
