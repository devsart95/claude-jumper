import AppKit
import SpriteKit
import Testing
@testable import ClaudeJumper

@MainActor
struct GameSceneTests {
    @Test func aRunWithoutJumpingEndsAtTheFirstObstacle() {
        withRun { scene, play in
            scene.handleSpace()
            play(12)
            #expect(scene.state == .gameOver)
            #expect((20...120).contains(scene.score), "ended at \(scene.score) points")
        }
    }

    @Test func aSpaceRightAfterACrashDoesNotRestartTheRun() {
        withRun { scene, play in
            scene.handleSpace()
            while scene.state != .gameOver { play(1.0 / 60) }

            scene.handleSpace()
            #expect(scene.state == .gameOver)

            play(0.6)
            scene.handleSpace()
            #expect(scene.state == .running)
        }
    }

    @Test func slowFramesDoNotSlowTheRunDown() {
        withRun(fps: 10) { scene, play in
            scene.handleSpace()
            play(3)
            #expect((28...30).contains(scene.score), "\(scene.score) points after 3 s at 10 fps")
        }
    }

    @Test func theControlsFollowTheTrackAfterItIsHidden() throws {
        _ = NSApplication.shared
        let window = FloatingGameWindow(screen: try #require(NSScreen.main))
        defer { window.hideGame() }

        window.hideGame()
        window.showGame()
        #expect(window.childWindows?.count == 1)
    }
}

/// Runs a scene against throwaway defaults, driving `update` from a fake clock.
@MainActor
private func withRun(fps: Double = 60, _ body: (GameScene, (Double) -> Void) -> Void) {
    let suite = "ClaudeJumperTests.\(UUID().uuidString)"
    guard let defaults = UserDefaults(suiteName: suite) else { return }
    defer { defaults.removePersistentDomain(forName: suite) }

    let scene = GameScene(size: CGSize(width: 1_180, height: 280), theme: .darkBackground, defaults: defaults)
    scene.didMove(to: SKView())
    var clock: TimeInterval = 1
    body(scene) { seconds in
        for _ in 0..<max(1, Int(seconds * fps)) {
            scene.update(clock)
            clock += 1 / fps
        }
    }
}
