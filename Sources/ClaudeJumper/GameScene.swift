import AppKit
@preconcurrency import SpriteKit

final class GameScene: SKScene {
    enum State { case waiting, running, paused, gameOver }

    private struct Obstacle {
        let node: SKShapeNode
        let size: CGSize
    }

    private static let groundY: CGFloat = 36

    private let mascot = MascotNode()
    private let ground = SKShapeNode()
    private let scoreLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    private let hintLabel = SKLabelNode(fontNamed: "HelveticaNeue-Medium")
    private let highScoreLabel = SKLabelNode(fontNamed: "Menlo-Regular")
    private var obstacles: [Obstacle] = []
    private var state: State = .waiting
    private var lastUpdate: TimeInterval = 0
    private var spawnElapsed: TimeInterval = 0
    private var scoreElapsed: TimeInterval = 0
    private var nextSpawnDelay = RunnerPhysics.firstObstacleDelay
    private var lift: CGFloat = 0
    private var verticalVelocity: CGFloat = 0
    private var isGrounded = true
    private(set) var visualTheme = GameTheme.saved
    private(set) var score = 0
    private var highScore: Int {
        get { UserDefaults.standard.integer(forKey: "highScore") }
        set { UserDefaults.standard.set(newValue, forKey: "highScore") }
    }

    private var mascotX: CGFloat { max(112, size.width * 0.12) }

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
        for obstacle in obstacles {
            obstacle.node.fillColor = theme.foreground
            obstacle.node.strokeColor = theme.foreground
        }
    }

    private func createGround() {
        let line = CGMutablePath()
        line.move(to: CGPoint(x: 16, y: Self.groundY))
        line.addLine(to: CGPoint(x: size.width - 16, y: Self.groundY))
        ground.path = line
        ground.strokeColor = visualTheme.foreground
        ground.lineWidth = 2
        ground.alpha = 0.72
        addChild(ground)
    }

    private func createMascot() {
        placeMascot()
        addChild(mascot)
    }

    private func placeMascot() {
        mascot.position = CGPoint(x: mascotX, y: Self.groundY + MascotNode.renderedSize.height / 2 + lift)
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
        verticalVelocity = RunnerPhysics.takeoffVelocity
        mascot.setAirborne(true)
        mascot.run(.sequence([
            .scale(to: 0.92, duration: 0.06),
            .scale(to: 1.0, duration: 0.11)
        ]))
    }

    private func setPaused(_ paused: Bool) {
        state = paused ? .paused : .running
        mascot.setRunning(!paused)
        hintLabel.text = paused ? "PAUSA  ·  ESPACIO PARA SEGUIR" : ""
    }

    private func reset() {
        obstacles.forEach { $0.node.removeFromParent() }
        obstacles.removeAll()
        lift = 0
        verticalVelocity = 0
        isGrounded = true
        placeMascot()
        mascot.setAirborne(false)
        score = 0
        spawnElapsed = 0
        scoreElapsed = 0
        nextSpawnDelay = RunnerPhysics.firstObstacleDelay
        updateLabels()
    }

    private func spawnObstacle() {
        guard let obstacleSize = RunnerPhysics.obstacleSizes.randomElement() else { return }
        let node = SKShapeNode(rectOf: obstacleSize, cornerRadius: obstacleSize.width > 40 ? 5 : 2)
        node.fillColor = visualTheme.foreground
        node.strokeColor = visualTheme.foreground
        // Every obstacle enters with its left edge at the scene's right edge, so the time between
        // two arrivals is exactly the spawn interval, whatever their widths.
        node.position = CGPoint(x: size.width + obstacleSize.width / 2, y: Self.groundY + obstacleSize.height / 2)
        node.addChild(makeNotch(for: obstacleSize, y: obstacleSize.height * 0.16))
        if obstacleSize.width >= 38 {
            node.addChild(makeNotch(for: obstacleSize, y: -obstacleSize.height * 0.18))
        }
        addChild(node)
        obstacles.append(Obstacle(node: node, size: obstacleSize))
        nextSpawnDelay = .random(in: RunnerPhysics.obstacleInterval)
    }

    private func makeNotch(for obstacleSize: CGSize, y: CGFloat) -> SKShapeNode {
        let notch = SKShapeNode(rectOf: CGSize(width: max(5, obstacleSize.width * 0.30), height: 6), cornerRadius: 1)
        notch.fillColor = Theme.terracotta
        notch.strokeColor = .clear
        notch.position.y = y
        return notch
    }

    override func update(_ currentTime: TimeInterval) {
        defer { lastUpdate = currentTime }
        guard state == .running, lastUpdate > 0 else { return }
        let dt = min(currentTime - lastUpdate, RunnerPhysics.maxStep)

        spawnElapsed += dt
        if spawnElapsed >= nextSpawnDelay {
            spawnElapsed = 0
            spawnObstacle()
        }

        let speed = RunnerPhysics.speed(score: score)
        for obstacle in obstacles {
            obstacle.node.position.x -= speed * CGFloat(dt)
        }
        obstacles.removeAll { obstacle in
            let isGone = obstacle.node.position.x < -obstacle.size.width
            if isGone { obstacle.node.removeFromParent() }
            return isGone
        }

        if !isGrounded {
            (lift, verticalVelocity) = RunnerPhysics.step(height: lift, velocity: verticalVelocity, dt: dt)
            if lift <= 0 {
                lift = 0
                verticalVelocity = 0
                isGrounded = true
                mascot.setAirborne(false)
            }
            placeMascot()
        }

        if hitsObstacle() {
            finishGame()
            return
        }

        scoreElapsed += dt
        if scoreElapsed >= RunnerPhysics.pointInterval {
            scoreElapsed -= RunnerPhysics.pointInterval
            score += 1
            updateLabels()
        }
    }

    private func hitsObstacle() -> Bool {
        let body = RunnerPhysics.mascotHitbox(centerX: mascotX, height: lift)
        return obstacles.contains { obstacle in
            body.intersects(RunnerPhysics.obstacleHitbox(size: obstacle.size, centerX: obstacle.node.position.x))
        }
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
