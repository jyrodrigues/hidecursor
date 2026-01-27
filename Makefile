.PHONY: build run clean

build:
	swift build -c release
	codesign --force --sign - .build/release/hidecursor

run: build
	.build/release/hidecursor

clean:
	swift package clean
