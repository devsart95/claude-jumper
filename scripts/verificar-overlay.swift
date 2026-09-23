// Con Claude Jumper abierta: `swift scripts/verificar-overlay.swift`. Pone una ventana propia en
// pantalla completa y mide si la pista sigue visible encima. Sale 1 si algo no se cumple.
import AppKit

let owner = "Claude Jumper"
let minimumLevel = Int(CGWindowLevelForKey(.statusWindow))
let settleAfterFullScreen: TimeInterval = 1.5
let fullScreenTimeout: TimeInterval = 10
// The control bar belongs to the same process; only the track is this tall.
let minimumTrackHeight: Double = 100

var failures = 0

func check(_ ok: Bool, _ message: String) {
    print(ok ? "✓" : "✗", message)
    if !ok { failures += 1 }
}

func onScreenTrack() -> [String: Any]? {
    let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] ?? []
    func height(_ window: [String: Any]) -> Double {
        (window[kCGWindowBounds as String] as? [String: Double])?["Height"] ?? 0
    }
    return windows.first {
        $0[kCGWindowOwnerName as String] as? String == owner && height($0) >= minimumTrackHeight
    }
}

guard let track = onScreenTrack() else {
    print("✗ \(owner) no está abierta: open \"dist/\(owner).app\"")
    exit(2)
}
let level = track[kCGWindowLayer as String] as? Int ?? 0
check(level >= minimumLevel, "nivel de la pista \(level), mínimo \(minimumLevel) (barra de estado)")

let app = NSApplication.shared
app.setActivationPolicy(.regular)
let window = NSWindow(
    contentRect: NSRect(x: 0, y: 0, width: 640, height: 400),
    styleMask: [.titled, .resizable],
    backing: .buffered,
    defer: false
)
window.collectionBehavior = .fullScreenPrimary
window.makeKeyAndOrderFront(nil)
app.activate(ignoringOtherApps: true)

NotificationCenter.default.addObserver(forName: NSWindow.didEnterFullScreenNotification, object: window, queue: .main) { _ in
    DispatchQueue.main.asyncAfter(deadline: .now() + settleAfterFullScreen) {
        check(onScreenTrack() != nil, "la pista se ve sobre una app en pantalla completa")
        exit(failures == 0 ? 0 : 1)
    }
}
DispatchQueue.main.async { window.toggleFullScreen(nil) }
DispatchQueue.main.asyncAfter(deadline: .now() + fullScreenTimeout) {
    print("✗ la ventana de prueba no entró en pantalla completa")
    exit(1)
}
app.run()
