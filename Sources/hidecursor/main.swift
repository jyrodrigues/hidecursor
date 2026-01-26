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
    private var appActivationObserver: NSObjectProtocol?
    private let displayID = CGMainDisplayID()
    private var statusItem: NSStatusItem?

    init(timeout: TimeInterval) {
        self.timeout = timeout
    }

    func start() {
        enableBackgroundCursorControl()
        setupMenuBar()
        startTimer()
        setupGlobalMonitor()
        setupAppActivationMonitor()
        NSApplication.shared.run()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = createMenuBarIcon()
            button.image?.isTemplate = true
        }

        let menu = NSMenu()
        let quitItem = NSMenuItem(title: "Quit HideCursor", action: #selector(quit), keyEquivalent: "")
        quitItem.target = self
        menu.addItem(quitItem)
        statusItem?.menu = menu
    }

    private func createMenuBarIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let path = NSBezierPath()

            // SVG viewBox is 24x24, scale to 18x18
            let scale: CGFloat = 18.0 / 24.0
            // Helper to convert SVG coords (Y-down) to NSBezierPath coords (Y-up)
            func p(_ x: CGFloat, _ y: CGFloat) -> NSPoint {
                NSPoint(x: x * scale, y: (24 - y) * scale)
            }
            func c(_ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat, _ x: CGFloat, _ y: CGFloat) {
                path.curve(to: p(x, y), controlPoint1: p(x1, y1), controlPoint2: p(x2, y2))
            }

            // Exact SVG path
            path.move(to: p(10.3172, 4.62596))
            path.line(to: p(15.8843, 6.67702))
            c(16.654, 6.96052, 17.31, 7.20218, 17.7857, 7.46219)
            c(18.2841, 7.73459, 18.7565, 8.11787, 18.8984, 8.76409)
            c(19.0403, 9.41032, 18.772, 9.95628, 18.4337, 10.4124)
            c(18.1108, 10.8479, 17.6164, 11.3422, 17.0364, 11.9221)
            path.line(to: p(16.3224, 12.6362))
            path.line(to: p(19.7466, 16.0604))
            c(19.9366, 16.2504, 20.105, 16.4188, 20.2357, 16.5686)
            c(20.3746, 16.7279, 20.5075, 16.9062, 20.5988, 17.1266)
            c(20.8005, 17.6136, 20.8005, 18.1608, 20.5988, 18.6479)
            c(20.5075, 18.8682, 20.3746, 19.0466, 20.2357, 19.2058)
            c(20.105, 19.3557, 19.9366, 19.5241, 19.7466, 19.714)
            path.line(to: p(19.714, 19.7466))
            c(19.5241, 19.9366, 19.3557, 20.105, 19.2058, 20.2357)
            c(19.0466, 20.3746, 18.8682, 20.5075, 18.6479, 20.5988)
            c(18.1608, 20.8005, 17.6136, 20.8005, 17.1266, 20.5988)
            c(16.9062, 20.5075, 16.7279, 20.3746, 16.5686, 20.2357)
            c(16.4188, 20.105, 16.2504, 19.9366, 16.0604, 19.7466)
            path.line(to: p(12.6362, 16.3224))
            path.line(to: p(11.9221, 17.0364))
            c(11.3422, 17.6164, 10.8479, 18.1108, 10.4124, 18.4337)
            c(9.95629, 18.772, 9.41032, 19.0403, 8.76409, 18.8984)
            c(8.11787, 18.7565, 7.73459, 18.2841, 7.46219, 17.7857)
            c(7.20218, 17.31, 6.96052, 16.654, 6.67702, 15.8843)
            path.line(to: p(4.62596, 10.3172))
            c(4.04508, 8.74059, 3.57969, 7.47746, 3.37319, 6.50443)
            c(3.16699, 5.53281, 3.15517, 4.56717, 3.86117, 3.86117)
            c(4.56717, 3.15517, 5.53281, 3.16699, 6.50444, 3.3732)
            c(7.47746, 3.5797, 8.74059, 4.04508, 10.3172, 4.62596)
            path.close()

            path.lineWidth = 1.0 * scale
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            path.setLineDash([4 * scale, 2 * scale], count: 2, phase: 0)
            NSColor.black.setStroke()
            path.stroke()

            return true
        }
        return image
    }

    @objc private func quit() {
        showCursor()
        NSApplication.shared.terminate(nil)
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

    private func setupAppActivationMonitor() {
        appActivationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppSwitch()
        }
    }

    private func handleMouseActivity() {
        showCursor()
        startTimer()
    }

    private func handleAppSwitch() {
        isCursorHidden = false
        startTimer()
    }

    deinit {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let observer = appActivationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
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
