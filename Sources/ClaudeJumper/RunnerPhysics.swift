import CoreGraphics
import Foundation

/// The rules of the run, in points and seconds, with heights measured up from the ground.
/// Nothing here touches SpriteKit, so the tests can check the rules without opening a window.
enum RunnerPhysics {
    static let gravity: CGFloat = 1_550
    static let jumpHeight: CGFloat = 125
    static let takeoffVelocity = (2 * gravity * jumpHeight).squareRoot()
    static let airtime = TimeInterval(2 * takeoffVelocity / gravity)

    static let startSpeed: CGFloat = 255
    static let topSpeed: CGFloat = 455
    /// The run keeps getting faster for its whole first minute.
    static let timeToTopSpeed: TimeInterval = 60
    static let acceleration = (topSpeed - startSpeed) / CGFloat(timeToTopSpeed)
    static let pointsPerSecond: Double = 10

    /// Longest single step of the simulation, so an obstacle can't pass through the mascot between checks.
    static let maxStep: TimeInterval = 1.0 / 20
    /// After a stall (the Mac waking up, a dragged window) the run catches up this much at most.
    static let maxCatchUp: TimeInterval = 0.25

    static let firstObstacleDelay: TimeInterval = 1.5
    /// Even after the latest jump that still clears an obstacle, you land this long before the
    /// last moment to jump the next one.
    static let timingMargin: TimeInterval = 0.2
    /// Random rest on top of that, so the rhythm doesn't feel mechanical.
    static let restBetweenObstacles: ClosedRange<TimeInterval> = 0...0.4

    static let obstacleSizes: [CGSize] = [
        CGSize(width: 22, height: 34),
        CGSize(width: 30, height: 48),
        CGSize(width: 20, height: 64),
        CGSize(width: 48, height: 30),
        CGSize(width: 38, height: 42)
    ]

    // Hitboxes are a little smaller than what you see, so grazing a corner doesn't end the run.
    private static let mascotBody = CGSize(width: 52, height: 48)
    private static let mascotForgiveness = CGSize(width: 3, height: 2)
    private static let obstacleForgiveness = CGSize(width: 2, height: 1)

    private static let distanceToTopSpeed = distance(atRunTime: timeToTopSpeed)

    static func score(atRunTime time: TimeInterval) -> Int {
        Int(time * pointsPerSecond)
    }

    /// How far the track has scrolled after `time` seconds of running.
    static func distance(atRunTime time: TimeInterval) -> CGFloat {
        let ramp = CGFloat(min(time, timeToTopSpeed))
        let cruise = CGFloat(max(0, time - timeToTopSpeed))
        return startSpeed * ramp + acceleration * ramp * ramp / 2 + topSpeed * cruise
    }

    static func runTime(atDistance distance: CGFloat) -> TimeInterval {
        guard distance < distanceToTopSpeed else {
            return timeToTopSpeed + TimeInterval((distance - distanceToTopSpeed) / topSpeed)
        }
        let root = (startSpeed * startSpeed + 2 * acceleration * distance).squareRoot()
        return TimeInterval((root - startSpeed) / acceleration)
    }

    /// Time between two obstacles reaching the mascot. A taller next obstacle needs an earlier
    /// takeoff, and a taller first one lets you leave sooner, so the gap adjusts for both.
    static func arrivalGap(from first: CGSize, to next: CGSize, rest: TimeInterval) -> TimeInterval {
        airtime + riseTime(over: next) - riseTime(over: first) + timingMargin + rest
    }

    /// How long after takeoff the mascot's hitbox gets above the obstacle's. That is also how early
    /// you must jump at the latest, counted from the moment the obstacle reaches you.
    static func riseTime(over size: CGSize) -> TimeInterval {
        let clearance = obstacleHitbox(size: size, centerX: 0).maxY - mascotHitbox(centerX: 0, height: 0).minY
        let spread = (takeoffVelocity * takeoffVelocity - 2 * gravity * clearance).squareRoot()
        return TimeInterval((takeoffVelocity - spread) / gravity)
    }

    /// Scroll distance at which the next obstacle enters, so it reaches the mascot `gap` seconds after
    /// the one that entered at `mark`. `approach` is the scroll from entering to touching the mascot.
    static func nextMark(after mark: CGFloat, approach: CGFloat, gap: TimeInterval) -> CGFloat {
        let arrival = runTime(atDistance: mark + approach)
        return distance(atRunTime: arrival + gap) - approach
    }

    /// Exact under constant gravity, so the arc is the same at 30, 60 or 120 fps.
    static func step(height: CGFloat, velocity: CGFloat, dt: TimeInterval) -> (height: CGFloat, velocity: CGFloat) {
        let t = CGFloat(dt)
        return (height + velocity * t - gravity * t * t / 2, velocity - gravity * t)
    }

    static func mascotHitbox(centerX: CGFloat, height: CGFloat) -> CGRect {
        CGRect(x: centerX - mascotBody.width / 2, y: height, width: mascotBody.width, height: mascotBody.height)
            .insetBy(dx: mascotForgiveness.width, dy: mascotForgiveness.height)
    }

    static func obstacleHitbox(size: CGSize, centerX: CGFloat) -> CGRect {
        CGRect(x: centerX - size.width / 2, y: 0, width: size.width, height: size.height)
            .insetBy(dx: obstacleForgiveness.width, dy: obstacleForgiveness.height)
    }

    /// Scroll from an obstacle entering with its left edge at `entryX` to its hitbox touching the mascot's.
    static func approachDistance(entryX: CGFloat, mascotX: CGFloat) -> CGFloat {
        entryX + obstacleForgiveness.width - mascotHitbox(centerX: mascotX, height: 0).maxX
    }
}
