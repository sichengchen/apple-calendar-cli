PREFIX ?= /usr/local

.PHONY: build release install uninstall clean

build:
	swift build -c debug

release:
	swift build -c release

install: release
	install -d $(PREFIX)/bin
	install .build/release/apple-calendar-cli $(PREFIX)/bin/apple-calendar-cli

uninstall:
	rm -f $(PREFIX)/bin/apple-calendar-cli

clean:
	swift package clean
