import AppKit
import CoreGraphics

// MARK: - CGS Private API Declarations

@_silgen_name("_CGSDefaultConnection")
func CGSDefaultConnection() -> Int32

@_silgen_name("CGSSetConnectionProperty")
func CGSSetConnectionProperty(_ cid: Int32, _ targetCID: Int32, _ key: CFString, _ value: CFBoolean)

// MARK: - CursorHider

class CursorHider {
    private var timer: Timer?
    private let timeout: TimeInterval
    private var isCursorHidden = false
    private var globalMonitor: Any?
    private let displayID = CGMainDisplayID()

    init(timeout: TimeInterval) {
        self.timeout = timeout
    }

    func start() {
        enableBackgroundCursorControl()
        startTimer()
        setupGlobalMonitor()
        NSApplication.shared.run()
    }

    private func enableBackgroundCursorControl() {
        let key = "SetsCursorInBackground" as CFString
        CGSSetConnectionProperty(
            CGSDefaultConnection(),
            CGSDefaultConnection(),
            key,
            kCFBooleanTrue
        )
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { [weak self] _ in
            self?.hideCursor()
        }
        timer?.tolerance = 0.1
    }

    private func hideCursor() {
        guard !isCursorHidden else { return }
        CGDisplayHideCursor(displayID)
        isCursorHidden = true
    }

    private func showCursor() {
        guard isCursorHidden else { return }
        CGDisplayShowCursor(displayID)
        isCursorHidden = false
    }

    private func setupGlobalMonitor() {
        let eventMask: NSEvent.EventTypeMask = [
            .mouseMoved,
            .leftMouseDown,
            .rightMouseDown,
            .leftMouseDragged,
            .rightMouseDragged,
            .scrollWheel
        ]

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: eventMask) { [weak self] _ in
            self?.handleMouseActivity()
        }
    }

    private func handleMouseActivity() {
        showCursor()
        startTimer()
    }

    deinit {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
        }
        timer?.invalidate()
        showCursor()
    }
}

// MARK: - Main

var timeout: TimeInterval = 3.0

if CommandLine.arguments.count > 1 {
    if let parsedTimeout = TimeInterval(CommandLine.arguments[1]) {
        timeout = parsedTimeout
    } else {
        fputs("Usage: hidecursor [timeout_seconds]\n", stderr)
        fputs("  timeout_seconds: Time in seconds before hiding cursor (default: 3.0)\n", stderr)
        exit(1)
    }
}

let _ = NSApplication.shared

signal(SIGINT) { _ in
    CGDisplayShowCursor(CGMainDisplayID())
    exit(0)
}

print("hidecursor: Hiding cursor after \(timeout) seconds of inactivity")
print("Press Ctrl+C to exit")

let hider = CursorHider(timeout: timeout)
hider.start()
