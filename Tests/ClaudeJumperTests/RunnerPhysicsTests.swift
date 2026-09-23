import CoreGraphics
import Foundation
import Testing
@testable import ClaudeJumper

/// The design rules of the run. Expected values come from the closed-form jump arc,
/// never from the game's own stepping code.
struct RunnerPhysicsTests {
    @Test(arguments: [30.0, 60.0, 120.0])
    func jumpPeaksAtTheDesignedHeightAtAnyFrameRate(fps: Double) {
        var height: CGFloat = 0
        var velocity = RunnerPhysics.takeoffVelocity
        var peak: CGFloat = 0
        repeat {
            (height, velocity) = RunnerPhysics.step(height: height, velocity: velocity, dt: 1 / fps)
            peak = max(peak, height)
        } while height > 0
        #expect(abs(peak - 125) < 0.5, "peak \(peak) pt at \(fps) fps")
    }

    @Test(arguments: RunnerPhysics.obstacleSizes)
    func everyObstacleGivesAtLeastAThirdOfASecondToTimeTheJump(size: CGSize) {
        let window = takeoffWindow(for: size, speed: RunnerPhysics.startSpeed)
        #expect(window.latest - window.earliest >= 0.3, "\(size)")
    }

    @Test func youAlwaysLandWithTimeToSpareBeforeTheNextJump() {
        for first in RunnerPhysics.obstacleSizes {
            for next in RunnerPhysics.obstacleSizes {
                let landing = takeoffWindow(for: first, speed: RunnerPhysics.startSpeed).earliest + RunnerPhysics.airtime
                let lastChance = RunnerPhysics.obstacleInterval.lowerBound
                    + takeoffWindow(for: next, speed: RunnerPhysics.startSpeed).latest
                #expect(lastChance - landing >= 0.4, "\(first) then \(next)")
            }
        }
    }
}

/// Takeoff times that clear an obstacle, counted from the moment its hitbox reaches the mascot's.
/// The start speed is the tightest case: faster runs cross the obstacle sooner and only widen the window.
private func takeoffWindow(for size: CGSize, speed: CGFloat) -> (earliest: TimeInterval, latest: TimeInterval) {
    let mascot = RunnerPhysics.mascotHitbox(centerX: 0, height: 0)
    let obstacle = RunnerPhysics.obstacleHitbox(size: size, centerX: 0)
    let clearance = obstacle.maxY - mascot.minY
    let crossing = TimeInterval((mascot.width + obstacle.width) / speed)

    // h(t) = v·t − g·t²/2 crosses the clearance going up and coming down.
    let v = RunnerPhysics.takeoffVelocity
    let g = RunnerPhysics.gravity
    let spread = (v * v - 2 * g * clearance).squareRoot()
    let risesAbove = TimeInterval((v - spread) / g)
    let fallsBelow = TimeInterval((v + spread) / g)
    return (earliest: crossing - fallsBelow, latest: -risesAbove)
}
