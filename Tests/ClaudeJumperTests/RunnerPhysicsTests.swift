import CoreGraphics
import Foundation
import Testing
@testable import ClaudeJumper

/// The design rules of the run. Expected values come from the closed-form jump arc and from
/// integrating the speed numerically, never from the game's own formulas.
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

    @Test func aLastMomentJumpStillLandsInTimeForTheNextObstacle() {
        for first in RunnerPhysics.obstacleSizes {
            for next in RunnerPhysics.obstacleSizes {
                let gap = RunnerPhysics.arrivalGap(from: first, to: next, rest: 0)
                let landing = takeoffWindow(for: first, speed: RunnerPhysics.startSpeed).latest + RunnerPhysics.airtime
                let lastChance = gap + takeoffWindow(for: next, speed: RunnerPhysics.startSpeed).latest
                #expect(lastChance - landing >= RunnerPhysics.timingMargin - 0.001, "\(first) then \(next)")
            }
        }
    }

    /// Entering at 0, 30, 58 and 70 s covers the ramp, the switch to top speed and the cruise.
    @Test(arguments: [0.0, 30.0, 58.0, 70.0])
    func obstaclesArriveAtTheirGapWhileTheRunSpeedsUp(entryTime: TimeInterval) {
        let approach: CGFloat = 1_000
        let gap: TimeInterval = 1
        let first = RunnerPhysics.distance(atRunTime: entryTime)
        let next = RunnerPhysics.nextMark(after: first, approach: approach, gap: gap)

        let arrivals = timesToScroll([first + approach, next + approach])
        #expect(abs(arrivals[1] - arrivals[0] - gap) < 0.005, "gap \(arrivals[1] - arrivals[0]) s")
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

/// Run times at which the track has scrolled each distance, integrating the speed in 1 ms steps.
/// The speed law comes from the design: from 255 to 455 pt/s, evenly over the first minute.
private func timesToScroll(_ distances: [CGFloat]) -> [TimeInterval] {
    func speed(at time: TimeInterval) -> CGFloat { min(455, 255 + 200 * CGFloat(time) / 60) }
    let dt: TimeInterval = 0.001
    var time: TimeInterval = 0
    var scrolled: CGFloat = 0
    return distances.map { target in
        while scrolled < target {
            scrolled += speed(at: time + dt / 2) * CGFloat(dt)
            time += dt
        }
        return time
    }
}
