import AppKit
import SpriteKit

@MainActor
private final class DragSurfaceView: NSView {
    weak var gameWindow: FloatingGameWindow?
    var accentColor = Theme.creatorBlue { didSet { needsDisplay = true } }
    private var mouseStart = CGPoint.zero
    private var windowStart = CGPoint.zero

    override func mouseDown(with event: NSEvent) {
        guard let gameWindow else { return }
        mouseStart = NSEvent.mouseLocation
        windowStart = gameWindow.frame.origin
        NSCursor.closedHand.push()
    }

    override func mouseDragged(with event: NSEvent) {
        guard let gameWindow else { return }
        let current = NSEvent.mouseLocation
        gameWindow.setFrameOrigin(CGPoint(
            x: windowStart.x + current.x - mouseStart.x,
            y: windowStart.y + current.y - mouseStart.y
        ))
    }

    override func mouseUp(with event: NSEvent) {
        NSCursor.pop()
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .openHand)
    }

    override func draw(_ dirtyRect: NSRect) {
        accentColor.withAlphaComponent(0.16).setFill()
        NSBezierPath(roundedRect: bounds, xRadius: 10, yRadius: 10).fill()
        accentColor.setStroke()
        for offset in [-4.0, 0.0, 4.0] {
            let line = NSBezierPath()
            line.lineWidth = 1.5
            line.move(to: CGPoint(x: 13, y: bounds.midY + offset))
            line.line(to: CGPoint(x: bounds.maxX - 13, y: bounds.midY + offset))
            line.stroke()
        }
    }
}

@MainActor
final class FloatingGameWindow: NSWindow {
    let scene: GameScene
    var onThemeChanged: ((GameTheme) -> Void)?
    private var controlsWindow: NSPanel?
    private var themeButton: NSButton?
    private weak var usernameLabel: NSTextField?
    private weak var dragSurface: DragSurfaceView?
    private(set) var gameTheme = GameTheme.saved

    var isRecordingMode: Bool {
        get { controlsWindow?.contentView?.isHidden ?? false }
        set {
            controlsWindow?.contentView?.isHidden = newValue
            controlsWindow?.ignoresMouseEvents = newValue
        }
    }

    init(screen: NSScreen) {
        let width: CGFloat = min(1_180, screen.visibleFrame.width - 48)
        let size = CGSize(width: width, height: 280)
        let origin = CGPoint(
            x: screen.visibleFrame.midX - width / 2,
            y: screen.visibleFrame.minY + 10
        )
        scene = GameScene(size: size)
        scene.scaleMode = .resizeFill

        super.init(
            contentRect: NSRect(origin: origin, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        let container = NSView(frame: NSRect(origin: .zero, size: size))
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.clear.cgColor

        let spriteView = SKView(frame: container.bounds)
        spriteView.autoresizingMask = [.width, .height]
        spriteView.allowsTransparency = true
        spriteView.presentScene(scene)
        container.addSubview(spriteView)
        usernameLabel = addUsername(to: container, width: size.width, height: size.height)
        contentView = container

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        hidesOnDeactivate = false
        animationBehavior = .utilityWindow
        controlsWindow = makeControlsWindow(parentOrigin: origin, parentHeight: size.height)
        if let controlsWindow { addChildWindow(controlsWindow, ordered: .above) }
        setTheme(gameTheme, persist: false)
        showGame()
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    @objc private func closeGame() {
        NSApp.terminate(nil)
    }

    @objc private func minimizeGame() {
        controlsWindow?.orderOut(nil)
        orderOut(nil)
    }

    @objc private func jumpNow() {
        scene.handleSpace()
    }

    @objc private func toggleTheme() {
        setTheme(gameTheme.next)
    }

    func setTheme(_ theme: GameTheme, persist: Bool = true) {
        gameTheme = theme
        if persist { theme.save() }
        scene.applyTheme(theme)
        usernameLabel?.textColor = theme.signatureColor
        dragSurface?.accentColor = theme.creatorBlue
        themeButton?.image = NSImage(systemSymbolName: theme.symbolName, accessibilityDescription: theme.displayName)
        themeButton?.layer?.backgroundColor = theme.creatorBlue.cgColor
        themeButton?.toolTip = "Tema: \(theme.displayName). Cambiar tema"
        themeButton?.setAccessibilityLabel("Tema: \(theme.displayName). Cambiar tema")
        onThemeChanged?(theme)
    }

    func showGame() {
        orderFrontRegardless()
        controlsWindow?.orderFrontRegardless()
    }

    private func makeControlsWindow(parentOrigin: CGPoint, parentHeight: CGFloat) -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: parentOrigin.x + 12, y: parentOrigin.y + parentHeight - 40, width: 176, height: 28),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.hidesOnDeactivate = false

        let controls = NSView(frame: NSRect(x: 0, y: 0, width: 176, height: 28))
        let close = Self.controlButton(
            symbol: "xmark",
            color: NSColor.systemRed,
            label: "Cerrar Claude Jumper",
            action: #selector(FloatingGameWindow.closeGame),
            target: self
        )
        close.frame.origin = CGPoint(x: 4, y: 4)
        controls.addSubview(close)

        let minimize = Self.controlButton(
            symbol: "minus",
            color: NSColor.systemYellow,
            label: "Minimizar Claude Jumper",
            action: #selector(FloatingGameWindow.minimizeGame),
            target: self
        )
        minimize.frame.origin = CGPoint(x: 34, y: 4)
        controls.addSubview(minimize)

        let jump = Self.controlButton(
            symbol: "arrow.up",
            color: Theme.creatorBlue,
            label: "Saltar ahora",
            action: #selector(FloatingGameWindow.jumpNow),
            target: self
        )
        jump.frame.origin = CGPoint(x: 64, y: 4)
        controls.addSubview(jump)

        let theme = Self.controlButton(
            symbol: gameTheme.symbolName,
            color: gameTheme.creatorBlue,
            label: "Cambiar tema",
            action: #selector(FloatingGameWindow.toggleTheme),
            target: self
        )
        theme.frame.origin = CGPoint(x: 94, y: 4)
        controls.addSubview(theme)
        themeButton = theme

        let dragHandle = DragSurfaceView(frame: NSRect(x: 124, y: 4, width: 44, height: 20))
        dragHandle.gameWindow = self
        dragHandle.accentColor = gameTheme.creatorBlue
        dragHandle.toolTip = "Mover Claude Jumper"
        dragHandle.setAccessibilityLabel("Mover Claude Jumper")
        controls.addSubview(dragHandle)
        dragSurface = dragHandle
        panel.contentView = controls
        return panel
    }

    private static func controlButton(
        symbol: String,
        color: NSColor,
        label: String,
        action: Selector,
        target: AnyObject
    ) -> NSButton {
        let button = NSButton(frame: NSRect(x: 0, y: 0, width: 20, height: 20))
        button.isBordered = false
        button.bezelStyle = .circular
        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: label)
        button.contentTintColor = Theme.ink
        button.wantsLayer = true
        button.layer?.backgroundColor = color.cgColor
        button.layer?.cornerRadius = 10
        button.target = target
        button.action = action
        button.toolTip = label
        button.setAccessibilityLabel(label)
        return button
    }

    private func addUsername(to container: NSView, width: CGFloat, height: CGFloat) -> NSTextField {
        let username = NSTextField(labelWithString: Self.signature)
        username.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        username.textColor = gameTheme.signatureColor
        username.alignment = .center
        username.frame = NSRect(x: width / 2 - 110, y: height - 34, width: 220, height: 20)
        container.addSubview(username)
        return username
    }

    // `defaults write py.devsar.claudejumper signature "@you"`; an empty string hides it.
    private static var signature: String {
        UserDefaults.standard.string(forKey: "signature") ?? "@rojassartorio"
    }
}
