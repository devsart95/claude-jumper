import AppKit
import SpriteKit

final class MascotNode: SKNode {
    static let renderedSize = CGSize(width: 62, height: 62)

    private let sprite: SKSpriteNode
    private let shadow = SKShapeNode(ellipseOf: CGSize(width: 43, height: 7))

    init(theme: GameTheme) {
        let image: NSImage
        if let url = Bundle.main.url(forResource: "clawd-sunglasses", withExtension: "png"),
           let bundled = NSImage(contentsOf: url) {
            image = bundled
        } else {
            image = NSImage(size: Self.renderedSize)
        }

        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        sprite = SKSpriteNode(texture: texture, size: Self.renderedSize)
        super.init()

        shadow.fillColor = theme.shadow
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -30)
        shadow.zPosition = -1
        addChild(shadow)
        addChild(sprite)
    }

    required init?(coder: NSCoder) { nil }

    func applyTheme(_ theme: GameTheme) {
        shadow.fillColor = theme.shadow
    }

    func setRunning(_ running: Bool) {
        guard running else {
            removeAction(forKey: "bob")
            sprite.position.y = 0
            return
        }
        guard action(forKey: "bob") == nil else { return }
        run(.repeatForever(.sequence([
            .moveBy(x: 0, y: 1.5, duration: 0.10),
            .moveBy(x: 0, y: -1.5, duration: 0.10)
        ])), withKey: "bob")
    }

    func setAirborne(_ airborne: Bool) {
        shadow.run(.scale(to: airborne ? 0.58 : 1, duration: 0.12))
        shadow.run(.fadeAlpha(to: airborne ? 0.35 : 1, duration: 0.12))
    }
}
