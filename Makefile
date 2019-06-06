PREFIX ?= /usr/local
BIN_PATH = $(PREFIX)/bin
LIB_PATH = $(PREFIX)/lib/badonde
BUILD_PATH = .build/release

SWIFT_BIN_FILES = \
	$(BUILD_PATH)/badonde

SWIFT_LIB_FILES = \
	$(BUILD_PATH)/*.dylib \
	$(BUILD_PATH)/BadondeKit.swift* \
	$(BUILD_PATH)/Git.swift* \
	$(BUILD_PATH)/GitHub.swift* \
	$(BUILD_PATH)/Jira.swift* \
	$(BUILD_PATH)/Sugar.swift* \
	$(BUILD_PATH)/SwiftCLI.swift* \
	$(BUILD_PATH)/SwiftyStringScore.swift*

build:
	swift build --disable-sandbox -c release

install: build
	mkdir -p $(BIN_PATH)
	mkdir -p $(LIB_PATH)
	install $(SWIFT_BIN_FILES) $(BIN_PATH)
	install $(SWIFT_LIB_FILES) $(LIB_PATH)

test:
	swift test

uninstall:
	rm -rf $(BIN_PATH)/badonde
	rm -rf $(LIB_PATH)
	rm -rf ~/.badonde
