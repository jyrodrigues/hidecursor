# HideCursor

A macOS utility that automatically hides the cursor after a period of inactivity.

## Usage

```bash
# Build and install to ~/.local/bin
just install

# Run with default 3-second timeout
hidecursor

# Or run with custom timeout (in seconds)
hidecursor 5
```

Make sure `~/.local/bin` is on your `PATH`.

## Required Permissions

This app requires **Input Monitoring** permission to detect mouse movement and show the cursor when you move your mouse.

### When Running from Terminal

If you run this app from Terminal, iTerm, Warp, or another terminal emulator, you need to grant Input Monitoring permission to **your terminal app** (not hidecursor):

1. Open **System Settings > Privacy & Security > Input Monitoring**
2. Click the **+** button
3. Navigate to `/Applications` and select your terminal app
4. **Restart your terminal** for the permission to take effect
5. Run `hidecursor` again

### When Running Directly

If you run the binary directly (e.g., double-clicking or from Finder):

1. macOS should prompt you to grant Input Monitoring permission
2. If not prompted, manually add the app in **System Settings > Privacy & Security > Input Monitoring**

## How It Works

- The cursor hides automatically after the configured timeout (default: 3 seconds)
- Moving the mouse or clicking shows the cursor again
- A menu bar icon provides a way to quit the app
- Press Ctrl+C in the terminal to quit

## Troubleshooting

### Cursor hides but doesn't reappear when I move the mouse

This means Input Monitoring permission is not granted. Follow the permission steps above.

### Permission was granted but still not working

1. Remove the app/terminal from Input Monitoring
2. Re-add it
3. **Restart your terminal** (this step is important)
4. Run the app again

### Reset permissions completely

You can reset TCC permissions for testing:

```bash
# Reset for Terminal.app
tccutil reset All com.apple.Terminal

# Reset for your specific terminal (find bundle ID with: osascript -e 'id of app "iTerm"')
tccutil reset All com.googlecode.iterm2
```

## Building

Requires Swift 5.9+ and macOS 12+.

```bash
just build     # Build release binary
just run       # Build and run
just install   # Build and install to ~/.local/bin
just clean     # Clean build artifacts
```
