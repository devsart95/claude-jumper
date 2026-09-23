import SpriteKit
import Testing
@testable import ClaudeJumper

@MainActor
struct GameSceneTests {
    @Test func aRunWithoutJumpingEndsAtTheFirstObstacle() {
        let scene = GameScene(size: CGSize(width: 1_180, height: 280))
        scene.didMove(to: SKView())
        scene.handleSpace()

        var clock: TimeInterval = 1
        func play(seconds: Double) {
            for _ in 0..<Int(seconds * 60) {
                scene.update(clock)
                clock += 1.0 / 60
            }
        }
        play(seconds: 12)
        let finalScore = scene.score
        play(seconds: 1)

        #expect(scene.score == finalScore, "the run should be over")
        #expect((20...120).contains(finalScore), "ended at \(finalScore) points")
    }
}
