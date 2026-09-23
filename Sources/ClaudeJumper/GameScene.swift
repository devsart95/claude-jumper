import AppKit
@preconcurrency import SpriteKit

final class GameScene: SKScene {
    enum State { case waiting, running, paused, gameOver }

    private enum Geometry {
        static let groundY: CGFloat = 36
        static let gravity: CGFloat = 1_550
        static let maxObstacleHeight: CGFloat = 66
        static let obstacleClearance: CGFloat = 14
        static let minimumSpeed: CGFloat = 255
        static let maximumSpeed: CGFloat = 455

        // v = √(2gh). This guarantees the player's lower edge clears the
        // tallest obstacle plus a deliberate forgiveness margin.
        static let jumpHeight: CGFloat = 125
        static let jumpVelocity = sqrt(2 * gravity * jumpHeight)
        static let flightTime = (2 * jumpVelocity) / gravity
    }

    private let mascot = MascotNode()
    private let ground = SKShapeNode()
    private let scoreLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    private let hintLabel = SKLabelNode(fontNamed: "HelveticaNeue-Medium")
    private let highScoreLabel = SKLabelNode(fontNamed: "Menlo-Regular")
    private var state: State = .waiting
    private var lastUpdate: TimeInterval = 0
    private var spawnElapsed: TimeInterval = 0
    private var scoreElapsed: TimeInterval = 0
    private var nextSpawnDelay: TimeInterval = 1.5
    private var runSpeed: CGFloat = Geometry.minimumSpeed
    private var verticalVelocity: CGFloat = 0
    private var isGrounded = true
    private(set) var visualTheme = GameTheme.saved
    private(set) var score = 0
    private var highScore: Int {
        get { UserDefaults.standard.integer(forKey: "highScore") }
        set { UserDefaults.standard.set(newValue, forKey: "highScore") }
    }

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        anchorPoint = .zero
        createGround()
        createMascot()
        createLabels()
        applyTheme(visualTheme)
        updateLabels()
    }

    func applyTheme(_ theme: GameTheme) {
        visualTheme = theme
        ground.strokeColor = theme.foreground
        scoreLabel.fontColor = theme.foreground
        highScoreLabel.fontColor = theme.mutedForeground
        hintLabel.fontColor = theme.foreground
        mascot.applyTheme(theme)
        enumerateChildNodes(withName: "obstacle") { node, _ in
            guard let obstacle = node as? SKShapeNode else { return }
            obstacle.fillColor = theme.foreground
            obstacle.strokeColor = theme.foreground
        }
    }

    private func createGround() {
        let line = CGMutablePath()
        line.move(to: CGPoint(x: 16, y: Geometry.groundY))
        line.addLine(to: CGPoint(x: size.width - 16, y: Geometry.groundY))
        ground.path = line
        ground.strokeColor = visualTheme.foreground
        ground.lineWidth = 2
        ground.alpha = 0.72
        addChild(ground)
    }

    private func createMascot() {
        mascot.position = CGPoint(x: max(112, size.width * 0.12), y: Geometry.groundY + MascotNode.renderedSize.height / 2)
        addChild(mascot)
    }

    private func createLabels() {
        scoreLabel.fontSize = 16
        scoreLabel.fontColor = visualTheme.foreground
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.position = CGPoint(x: size.width - 22, y: size.height - 57)
        addChild(scoreLabel)

        highScoreLabel.fontSize = 10
        highScoreLabel.fontColor = visualTheme.mutedForeground
        highScoreLabel.horizontalAlignmentMode = .right
        highScoreLabel.position = CGPoint(x: size.width - 22, y: size.height - 74)
        addChild(highScoreLabel)

        hintLabel.fontSize = 13
        hintLabel.fontColor = visualTheme.foreground
        hintLabel.position = CGPoint(x: size.width / 2, y: size.height - 57)
        addChild(hintLabel)
    }

    func handleSpace() {
        switch state {
        case .waiting:
            start()
            jump()
        case .running:
            jump()
        case .paused:
            setPaused(false)
        case .gameOver:
            reset()
            start()
            jump()
        }
    }

    func togglePause() {
        guard state != .waiting, state != .gameOver else { return }
        setPaused(state == .running)
    }

    func resetHighScore() {
        highScore = 0
        updateLabels()
    }

    private func start() {
        state = .running
        hintLabel.text = ""
        mascot.setRunning(true)
    }

    private func jump() {
        guard state == .running, isGrounded else { return }
        isGrounded = false
        verticalVelocity = Geometry.jumpVelocity
        mascot.setAirborne(true)
        mascot.run(.sequence([
            .scale(to: 0.92, duration: 0.06),
            .scale(to: 1.0, duration: 0.11)
        ]))
    }

    private func setPaused(_ paused: Bool) {
        state = paused ? .paused : .running
        physicsWorld.speed = paused ? 0 : 1
        children.filter { $0.name == "obstacle" }.forEach { $0.isPaused = paused }
        mascot.setRunning(!paused)
        hintLabel.text = paused ? "PAUSA  ·  ESPACIO PARA SEGUIR" : ""
    }

    private func reset() {
        enumerateChildNodes(withName: "obstacle") { node, _ in node.removeFromParent() }
        mascot.position = CGPoint(x: max(112, size.width * 0.12), y: Geometry.groundY + MascotNode.renderedSize.height / 2)
        verticalVelocity = 0
        isGrounded = true
        mascot.setAirborne(false)
        score = 0
        runSpeed = Geometry.minimumSpeed
        spawnElapsed = 0
        scoreElapsed = 0
        nextSpawnDelay = 1.5
        physicsWorld.speed = 1
        updateLabels()
    }

    private func spawnObstacle() {
        let variants: [CGSize] = [
            CGSize(width: 22, height: 34),
            CGSize(width: 30, height: 48),
            CGSize(width: 20, height: 64),
            CGSize(width: 48, height: 30),
            CGSize(width: 38, height: 42)
        ]
        let obstacleSize = variants.randomElement() ?? variants[0]
        let obstacle = SKShapeNode(rectOf: obstacleSize, cornerRadius: obstacleSize.width > 40 ? 5 : 2)
        obstacle.name = "obstacle"
        obstacle.fillColor = visualTheme.foreground
        obstacle.strokeColor = visualTheme.foreground
        obstacle.position = CGPoint(x: size.width + obstacleSize.width, y: Geometry.groundY + obstacleSize.height / 2)
        let notch = SKShapeNode(rectOf: CGSize(width: max(5, obstacleSize.width * 0.30), height: 6), cornerRadius: 1)
        notch.fillColor = Theme.terracotta
        notch.strokeColor = .clear
        notch.position = CGPoint(x: 0, y: obstacleSize.height * 0.16)
        obstacle.addChild(notch)

        if obstacleSize.width >= 38 {
            let secondNotch = notch.copy() as! SKShapeNode
            secondNotch.position.y = -obstacleSize.height * 0.18
            obstacle.addChild(secondNotch)
        }
        addChild(obstacle)

        let jumpDistance = runSpeed * Geometry.flightTime
        let geometricSeparation = max(jumpDistance * 0.88, MascotNode.collisionSize.width + obstacleSize.width + 80)
        nextSpawnDelay = TimeInterval(geometricSeparation / runSpeed) + Double.random(in: 0.30...0.72)
    }

    override func update(_ currentTime: TimeInterval) {
        guard state == .running else { lastUpdate = currentTime; return }
        let delta = lastUpdate == 0 ? 0 : min(currentTime - lastUpdate, 1.0 / 20.0)
        lastUpdate = currentTime
        spawnElapsed += delta
        scoreElapsed += delta

        if spawnElapsed >= nextSpawnDelay {
            spawnElapsed = 0
            spawnObstacle()
        }

        runSpeed = min(Geometry.maximumSpeed, Geometry.minimumSpeed + CGFloat(score) * 1.25)
        enumerateChildNodes(withName: "obstacle") { [runSpeed] node, _ in
            node.position.x -= runSpeed * CGFloat(delta)
            if node.position.x < -40 { node.removeFromParent() }
        }

        if !isGrounded {
            verticalVelocity -= Geometry.gravity * CGFloat(delta)
            mascot.position.y += verticalVelocity * CGFloat(delta)
            let restingY = Geometry.groundY + MascotNode.renderedSize.height / 2
            if mascot.position.y <= restingY {
                mascot.position.y = restingY
                verticalVelocity = 0
                isGrounded = true
                mascot.setAirborne(false)
            }
        }

        if intersectsObstacle() {
            finishGame()
            return
        }

        if scoreElapsed >= 0.1 {
            scoreElapsed -= 0.1
            score += 1
            updateLabels()
        }

    }

    private func intersectsObstacle() -> Bool {
        let bodyCenterOffset = -(MascotNode.renderedSize.height - MascotNode.collisionSize.height) / 2
        let playerRect = CGRect(
            x: mascot.position.x - MascotNode.collisionSize.width / 2,
            y: mascot.position.y + bodyCenterOffset - MascotNode.collisionSize.height / 2,
            width: MascotNode.collisionSize.width,
            height: MascotNode.collisionSize.height
        ).insetBy(dx: 3, dy: 2)

        var collided = false
        enumerateChildNodes(withName: "obstacle") { node, stop in
            if playerRect.intersects(node.frame.insetBy(dx: 2, dy: 1)) {
                collided = true
                stop.pointee = true
            }
        }
        return collided
    }

    private func finishGame() {
        state = .gameOver
        mascot.setRunning(false)
        if score > highScore { highScore = score }
        updateLabels()
        hintLabel.text = "OUCH  ·  ESPACIO PARA REINTENTAR"
        NSSound.beep()
        run(.sequence([
            .moveBy(x: -5, y: 0, duration: 0.035),
            .moveBy(x: 10, y: 0, duration: 0.07),
            .moveBy(x: -5, y: 0, duration: 0.035)
        ]))
    }

    private func updateLabels() {
        scoreLabel.text = String(format: "%05d", score)
        highScoreLabel.text = "RÉCORD  " + String(format: "%05d", highScore)
        if state == .waiting { hintLabel.text = "ESPACIO PARA SALTAR" }
    }
}
