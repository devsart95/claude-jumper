import AppKit
import ApplicationServices

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: FloatingGameWindow?
    private var statusItem: NSStatusItem?
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var permissionTimer: Timer?
    private var permissionItem: NSMenuItem?
    private var lightThemeItem: NSMenuItem?
    private var darkThemeItem: NSMenuItem?
    private var recordingItem: NSMenuItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        guard let screen = NSScreen.main else { return }
        window = FloatingGameWindow(screen: screen)
        installLocalKeyboardMonitor()
        installStatusMenu()
        window?.onThemeChanged = { [weak self] theme in self?.updateThemeMenu(theme) }
        if let theme = window?.gameTheme { updateThemeMenu(theme) }
        configureGlobalKeyboardAccess()
    }

    func applicationWillTerminate(_ notification: Notification) {
        permissionTimer?.invalidate()
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
    }

    private func installLocalKeyboardMonitor() {
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 49, !event.isARepeat {
                self?.window?.scene.handleSpace()
            }
            return event
        }
    }

    private func configureGlobalKeyboardAccess() {
        if globalKeyboardAccessGranted() {
            installGlobalKeyboardMonitor()
            return
        }

        updatePermissionMenu(granted: false)
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        if AXIsProcessTrustedWithOptions(options) {
            installGlobalKeyboardMonitor()
        } else {
            startPermissionPolling()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.openAccessibilitySettings()
            }
        }
    }

    private func globalKeyboardAccessGranted() -> Bool {
        AXIsProcessTrusted() || CGPreflightListenEventAccess()
    }

    private func installGlobalKeyboardMonitor() {
        guard globalMonitor == nil else { return }
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == 49, !event.isARepeat else { return }
            Task { @MainActor in self?.window?.scene.handleSpace() }
        }
        permissionTimer?.invalidate()
        permissionTimer = nil
        updatePermissionMenu(granted: true)
    }

    private func startPermissionPolling() {
        permissionTimer?.invalidate()
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.globalKeyboardAccessGranted() else { return }
                self.installGlobalKeyboardMonitor()
            }
        }
    }

    private func installStatusMenu() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "figure.run", accessibilityDescription: "Claude Jumper")

        let menu = NSMenu()
        let title = NSMenuItem(title: "Claude Jumper", action: nil, keyEquivalent: "")
        title.isEnabled = false
        menu.addItem(title)

        let permission = NSMenuItem(title: "Entrada global: verificando…", action: nil, keyEquivalent: "")
        permission.isEnabled = false
        menu.addItem(permission)
        permissionItem = permission
        menu.addItem(.separator())

        let show = NSMenuItem(title: "Mostrar juego", action: #selector(showGame), keyEquivalent: "m")
        show.target = self
        menu.addItem(show)

        let recording = NSMenuItem(title: "Modo grabación (sin controles)", action: #selector(toggleRecordingMode), keyEquivalent: "")
        recording.target = self
        menu.addItem(recording)
        recordingItem = recording

        let pause = NSMenuItem(title: "Pausar", action: #selector(togglePause), keyEquivalent: "p")
        pause.target = self
        menu.addItem(pause)

        let jump = NSMenuItem(title: "Saltar ahora", action: #selector(jumpNow), keyEquivalent: "")
        jump.target = self
        menu.addItem(jump)

        let themeMenu = NSMenu(title: "Tema")
        let lightTheme = NSMenuItem(title: "Sobre fondo claro", action: #selector(useLightTheme), keyEquivalent: "")
        lightTheme.target = self
        themeMenu.addItem(lightTheme)
        lightThemeItem = lightTheme
        let darkTheme = NSMenuItem(title: "Sobre fondo oscuro", action: #selector(useDarkTheme), keyEquivalent: "")
        darkTheme.target = self
        themeMenu.addItem(darkTheme)
        darkThemeItem = darkTheme
        let themeRoot = NSMenuItem(title: "Tema", action: nil, keyEquivalent: "")
        themeRoot.submenu = themeMenu
        menu.addItem(themeRoot)

        let settings = NSMenuItem(title: "Permiso de accesibilidad…", action: #selector(openPermissionSettings), keyEquivalent: "")
        settings.target = self
        menu.addItem(settings)

        let reset = NSMenuItem(title: "Borrar récord", action: #selector(resetHighScore), keyEquivalent: "")
        reset.target = self
        menu.addItem(reset)
        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Salir", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        item.menu = menu
        statusItem = item
    }

    private func updatePermissionMenu(granted: Bool) {
        permissionItem?.title = granted ? "Entrada global: activa" : "Entrada global: sin permiso"
    }

    private func updateThemeMenu(_ theme: GameTheme) {
        lightThemeItem?.state = theme == .lightBackground ? .on : .off
        darkThemeItem?.state = theme == .darkBackground ? .on : .off
    }

    private func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else { return }
        NSWorkspace.shared.open(url)
    }

    @objc private func openPermissionSettings() { openAccessibilitySettings() }
    @objc private func showGame() { window?.showGame() }
    @objc private func jumpNow() { window?.scene.handleSpace() }
    @objc private func useLightTheme() { window?.setTheme(.lightBackground) }
    @objc private func useDarkTheme() { window?.setTheme(.darkBackground) }
    @objc private func togglePause() { window?.scene.togglePause() }
    @objc private func resetHighScore() { window?.scene.resetHighScore() }
    @objc private func quit() { NSApp.terminate(nil) }

    @objc private func toggleRecordingMode() {
        guard let window else { return }
        window.isRecordingMode.toggle()
        recordingItem?.state = window.isRecordingMode ? .on : .off
    }
}
