.PHONY: build run clean

build:
	swift build -c release

run: build
	.build/release/hidecursor

clean:
	swift package clean
