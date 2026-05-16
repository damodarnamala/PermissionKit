PREFIX ?= /usr/local

build:
	swift build -c release --disable-sandbox

install: build
	install -d "$(PREFIX)/bin/"
	install ".build/release/permissionkit" "$(PREFIX)/bin/permissionkit"

uninstall:
	rm -f "$(PREFIX)/bin/permissionkit"

clean:
	swift package clean

.PHONY: build install uninstall clean
