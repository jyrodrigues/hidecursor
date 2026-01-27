# Fix: Cursor Hiding App Not Working Due to Missing Input Monitoring Permission

## Root Cause

The app uses `NSEvent.addGlobalMonitorForEvents()` to detect mouse activity, which **requires Input Monitoring permission** on macOS 10.15+. The issue is:

1. **No permission prompt appears** because:
   - When running from Terminal, **Terminal.app needs the permission**, not the CLI tool itself
   - macOS associates the permission with the parent process (Terminal/iTerm2/Warp)
   - The app never explicitly requests permission using the proper APIs

2. **Silent failure** - When permission is missing, the global event monitor callback never fires, so:
   - The cursor hides after timeout (this still works)
   - The cursor never reappears on mouse movement (this is broken)

## Why It Stopped Working

Even though you changed the app name and recompiled, **the problem is with Terminal.app**, not your app. If you previously granted Input Monitoring to Terminal and later revoked it (or macOS revoked it after a system update), the app would stop working.

## Implementation Plan

### 1. Modify `Sources/hidecursor/main.swift`

**Add permission check at startup** using CoreGraphics APIs:

```swift
// These are already available via CoreGraphics
// CGPreflightListenEventAccess() - checks if permission is granted
// CGRequestListenEventAccess() - triggers the permission prompt
```

Changes to make:
- Add `checkInputMonitoringPermission()` function that calls `CGPreflightListenEventAccess()` and `CGRequestListenEventAccess()`
- Add `printPermissionInstructions()` function with clear instructions for Terminal vs direct execution
- Modify `start()` to check permissions before setting up monitors
- Modify `setupGlobalMonitor()` to verify the monitor was created (it returns `nil` on failure)

### 2. Update `Makefile`

Add ad-hoc code signing to improve permission handling:

```makefile
build:
	swift build -c release
	codesign --force --sign - .build/release/hidecursor
```

### 3. Create `README.md`

Document:
- What the app does
- Permission requirements
- How to grant Input Monitoring permission (for Terminal and direct execution)
- Troubleshooting steps

## Files to Modify

| File | Changes |
|------|---------|
| `Sources/hidecursor/main.swift` | Add permission check/request logic and user feedback |
| `Makefile` | Add ad-hoc code signing |
| `README.md` | Create with usage and permission documentation |

## Immediate Fix (Manual)

To make the app work right now without code changes:

1. Open **System Settings > Privacy & Security > Input Monitoring**
2. Click **+** and add **Terminal.app** (or iTerm, Warp, etc.)
3. Restart Terminal
4. Run the app again

## Verification

After implementation:
1. Remove Terminal from Input Monitoring list
2. Run the app - should see permission warning
3. Grant permission to Terminal
4. Restart Terminal and run app - cursor should hide AND reappear on mouse movement
