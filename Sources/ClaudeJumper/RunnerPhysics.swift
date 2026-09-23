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
    static let speedGainPerPoint: CGFloat = 1.25
    static let pointInterval: TimeInterval = 0.1

    /// A longer frame is cut to this, so a hitch can't carry an obstacle through the mascot.
    static let maxStep: TimeInterval = 1.0 / 20

    static let firstObstacleDelay: TimeInterval = 1.5
    /// A full jump plus a pause, so you always land before the next obstacle asks for another jump.
    static let obstacleInterval: ClosedRange<TimeInterval> = (airtime + 0.20)...(airtime + 0.62)

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

    static func speed(score: Int) -> CGFloat {
        min(topSpeed, startSpeed + CGFloat(score) * speedGainPerPoint)
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
}
