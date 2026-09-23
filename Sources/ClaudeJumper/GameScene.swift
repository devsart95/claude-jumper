import AppKit
@preconcurrency import SpriteKit

final class GameScene: SKScene {
    enum State { case waiting, running, paused, gameOver }

    private struct Obstacle {
        let node: SKShapeNode
        let size: CGSize
        /// Track scroll at which its left edge crosses the right edge of the scene.
        let mark: CGFloat
    }

    private static let groundY: CGFloat = 36
    private static let highScoreKey = "highScore"
    /// A space pressed right after a crash is usually a late jump, not a request to play again.
    private static let restartDelay: TimeInterval = 0.5

    var onGameOver: (() -> Void)?

    private let defaults: UserDefaults
    private let mascot: MascotNode
    private let ground = SKShapeNode()
    private let scoreLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    private let hintLabel = SKLabelNode(fontNamed: "HelveticaNeue-Medium")
    private let highScoreLabel = SKLabelNode(fontNamed: "Menlo-Regular")
    private var obstacles: [Obstacle] = []
    private(set) var state: State = .waiting
    private var lastUpdate: TimeInterval = 0
    private var gameOverTime: TimeInterval = 0
    private var runTime: TimeInterval = 0
    private var lift: CGFloat = 0
    private var verticalVelocity: CGFloat = 0
    private var isGrounded = true
    private(set) var visualTheme: GameTheme
    private(set) var score = 0
    private var highScore: Int {
        get { defaults.integer(forKey: Self.highScoreKey) }
        set { defaults.set(newValue, forKey: Self.highScoreKey) }
    }

    private var mascotX: CGFloat { max(112, size.width * 0.12) }
    private var approachDistance: CGFloat {
        RunnerPhysics.approachDistance(entryX: size.width, mascotX: mascotX)
    }

    init(size: CGSize, theme: GameTheme, defaults: UserDefaults = .standard) {
        self.defaults = defaults
        visualTheme = theme
        mascot = MascotNode(theme: theme)
        super.init(size: size)
    }

    required init?(coder: NSCoder) { nil }

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
            guard lastUpdate - gameOverTime >= Self.restartDelay else { return }
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
        addObstacle(after: nil)
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
        runTime = 0
        lift = 0
        verticalVelocity = 0
        isGrounded = true
        placeMascot()
        mascot.setAirborne(false)
        score = 0
        updateLabels()
    }

    /// Places the next obstacle past the right edge, far enough behind `previous` that a
    /// last-moment jump over it still lands in time for this one.
    private func addObstacle(after previous: Obstacle?) {
        guard let obstacleSize = RunnerPhysics.obstacleSizes.randomElement() else { return }
        let mark: CGFloat
        if let previous {
            let gap = RunnerPhysics.arrivalGap(
                from: previous.size,
                to: obstacleSize,
                rest: .random(in: RunnerPhysics.restBetweenObstacles)
            )
            mark = RunnerPhysics.nextMark(after: previous.mark, approach: approachDistance, gap: gap)
        } else {
            mark = RunnerPhysics.distance(atRunTime: runTime + RunnerPhysics.firstObstacleDelay)
        }

        let node = SKShapeNode(rectOf: obstacleSize, cornerRadius: obstacleSize.width > 40 ? 5 : 2)
        node.fillColor = visualTheme.foreground
        node.strokeColor = visualTheme.foreground
        node.addChild(makeNotch(for: obstacleSize, y: obstacleSize.height * 0.16))
        if obstacleSize.width >= 38 {
            node.addChild(makeNotch(for: obstacleSize, y: -obstacleSize.height * 0.18))
        }
        let obstacle = Obstacle(node: node, size: obstacleSize, mark: mark)
        place(obstacle, scrolled: RunnerPhysics.distance(atRunTime: runTime))
        addChild(node)
        obstacles.append(obstacle)
    }

    private func makeNotch(for obstacleSize: CGSize, y: CGFloat) -> SKShapeNode {
        let notch = SKShapeNode(rectOf: CGSize(width: max(5, obstacleSize.width * 0.30), height: 6), cornerRadius: 1)
        notch.fillColor = Theme.terracotta
        notch.strokeColor = .clear
        notch.position.y = y
        return notch
    }

    private func place(_ obstacle: Obstacle, scrolled: CGFloat) {
        let leftEdge = size.width + obstacle.mark - scrolled
        obstacle.node.position = CGPoint(
            x: leftEdge + obstacle.size.width / 2,
            y: Self.groundY + obstacle.size.height / 2
        )
    }

    override func update(_ currentTime: TimeInterval) {
        defer { lastUpdate = currentTime }
        guard state == .running, lastUpdate > 0 else { return }
        let dt = min(currentTime - lastUpdate, RunnerPhysics.maxStep)
        runTime += dt
        let scrolled = RunnerPhysics.distance(atRunTime: runTime)

        // The newest obstacle is always waiting off screen; once it enters, queue the one after it.
        if let newest = obstacles.last, scrolled >= newest.mark {
            addObstacle(after: newest)
        }
        for obstacle in obstacles {
            place(obstacle, scrolled: scrolled)
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
            finishGame(at: currentTime)
            return
        }

        let newScore = RunnerPhysics.score(atRunTime: runTime)
        if newScore != score {
            score = newScore
            updateLabels()
        }
    }

    private func hitsObstacle() -> Bool {
        let body = RunnerPhysics.mascotHitbox(centerX: mascotX, height: lift)
        return obstacles.contains { obstacle in
            body.intersects(RunnerPhysics.obstacleHitbox(size: obstacle.size, centerX: obstacle.node.position.x))
        }
    }

    private func finishGame(at time: TimeInterval) {
        state = .gameOver
        gameOverTime = time
        mascot.setRunning(false)
        if score > highScore { highScore = score }
        updateLabels()
        hintLabel.text = "OUCH  ·  ESPACIO PARA REINTENTAR"
        onGameOver?()
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
