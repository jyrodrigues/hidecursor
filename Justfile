# Build release binary
build:
    swift build -c release
    codesign --force --sign - .build/release/hidecursor

# Build and run
run: build
    .build/release/hidecursor

# Clean build artifacts
clean:
    swift package clean

# Build and install binary to ~/.local/bin
install: build
    #!/usr/bin/env bash
    set -euo pipefail
    install -d "$HOME/.local/bin"
    install -m 755 .build/release/hidecursor "$HOME/.local/bin/hidecursor"
    echo "Installed hidecursor to ~/.local/bin/hidecursor"
