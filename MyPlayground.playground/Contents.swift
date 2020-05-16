//: A SpriteKit based Playground

import PlaygroundSupport
import SpriteKit

class GameScene: SKScene {

    private var playerSpriteViewModel : PlayerSpriteViewModel?
    private var scoreLabelViewModel : ScoreLabelViewModel?
    private var direction : Direction?
    private var life = 3
    private var powers = [Power]()

    override func didMove(to view: SKView) {

        scoreLabelViewModel = ScoreLabelViewModel(label: childNode(withName: Identifiers.kScoreLabel) as? SKLabelNode)
        let playerSprite = childNode(withName: Identifiers.kPlayer) as? SKSpriteNode
        playerSpriteViewModel = PlayerSpriteViewModel(playerSprite: playerSprite)

        let beamSprite = childNode(withName: Identifiers.kBeam) as? SKSpriteNode
        let beamSize = beamSprite?.size ?? .zero
        let anchorPoint = beamSprite?.anchorPoint ?? CGPoint.zero
        beamSprite?.physicsBody = SKPhysicsBody(rectangleOf: beamSize, center: CGPoint(x: anchorPoint.x + beamSize.width/2.0, y: anchorPoint.y))
        beamSprite?.physicsBody?.isDynamic = true
        beamSprite?.physicsBody?.categoryBitMask = PhysicsCategory.none
        beamSprite?.physicsBody?.contactTestBitMask = PhysicsCategory.player
        beamSprite?.physicsBody?.collisionBitMask = PhysicsCategory.none

        fadeIn(node: playerSprite, duration: 3.0, completion: { [weak self] in
            self?.playerSpriteViewModel?.animateRight{ [weak self] in
                let label = self?.childNode(withName: Identifiers.kWhatLabel) as? SKLabelNode
                label?.run(SKAction.fadeIn(withDuration: 0.1), completion: {

                    label?.run(SKAction.sequence([SKAction.wait(forDuration: 2.0), SKAction.fadeOut(withDuration: 0.1)]), completion: { [weak self] in

                        self?.playerSpriteViewModel?.animateLeft{ [weak self] in
                            label?.run(SKAction.fadeIn(withDuration: 0.1))
                            label?.position.x = self?.playerSpriteViewModel?.currentXPosition ?? 0.0
                            label?.text = "Where am I?"
                            self?.showBg()
                        }
                    })
                })
            }
        })

        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self

        updateLives()
    }
    
    @objc static override var supportsSecureCoding: Bool {
        // SKNode conforms to NSSecureCoding, so any subclass going
        // through the decoding process must support secure coding
        get {
            return true
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        guard let touch = touches.first else {return}
        let touchedPoint = touch.location(in: self)
        guard let touchedNode = nodes(at: touchedPoint).first else {return}
        
        if touchedNode.name == Identifiers.kStartGameButton{
            startGame()
        }else if touchedNode.name == Identifiers.kRetryButton{
            reset()
        }else if touchedNode.name == Identifiers.kLaserButton{
            useLaserPower()
        }else{
            handlePlayerTouch(touches: touches)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        direction = Direction.none
    }

    override func update(_ currentTime: TimeInterval) {
        moveSprite()
    }

    //MARK:- Private
    private func showBg(){
        let bg = childNode(withName: Identifiers.kStoryBG) as? SKSpriteNode
        fadeIn(node: bg, completion: {
            let dialogue = bg?.childNode(withName: Identifiers.kStoryLabel) as? SKLabelNode
            dialogue?.text = "Welcome to Pixeltain. Try and survive the falling rocks. Collect Question marks to get powers."
            dialogue?.numberOfLines = 0
            dialogue?.preferredMaxLayoutWidth = (bg?.size.width ?? 0.0) - 20.0
        })
    }

    private func reset(){
        let menuNode = childNode(withName: Identifiers.kMenu) as? SKSpriteNode
        let moveAnimation = SKAction.move(to: CGPoint(x: 0, y: -size.height/2.0), duration: 2.0)
        menuNode?.run(moveAnimation, completion: { [weak self] in
            self?.scoreLabelViewModel?.resetScore()
            self?.life = 3
            self?.updateLives()
            self?.powers.removeAll()
            self?.fadeOut(node: self?.childNode(withName: Identifiers.kLaserButton) as? SKSpriteNode)
            self?.playerSpriteViewModel?.updateSpritePosition(x: 0, direction: .none)
            self?.startGame()
        })
    }

    private func useLaserPower(){

        powers.removeAll(where: {$0 == .laser})
        fadeOut(node: childNode(withName: Identifiers.kLaserButton) as? SKSpriteNode)
        playerSpriteViewModel?.startLaser(laserNode : childNode(withName: Identifiers.kBeam) as? SKSpriteNode)
    }

    private func boulderHit(boulder : SKSpriteNode){
        boulder.removeFromParent()
        life = max(0, life - 1)
        updateLives()
        if life == 0{
            endAndShowMenu()
        }
    }

    private func boulderDestroyed(boulder : SKSpriteNode){

        boulder.removeFromParent()
        scoreLabelViewModel?.increaseScore()
    }

    private func powerUp(power : SKSpriteNode){
        power.removeFromParent()
        let value = Int.random(in: 0..<1)
        guard let currentPower = Power(rawValue: value) else {return}

        if !powers.contains(currentPower){
            powers.append(currentPower)
            if currentPower == .laser{
                fadeIn(node : childNode(withName: Identifiers.kLaserButton) as? SKSpriteNode, duration: 0.1)
            }
        }
    }

    private func fadeIn(node : SKSpriteNode?, duration : TimeInterval = 0.5, completion : (()->())? = nil){

        let fadeAction = SKAction.fadeIn(withDuration: duration)
        node?.run(fadeAction, completion: {
            completion?()
        })
    }

    private func fadeOut(node : SKSpriteNode?){

        let fadeAction = SKAction.fadeOut(withDuration: 1.0)
        node?.run(fadeAction)
    }

    private func endAndShowMenu(){

        removeAllActions()
        scoreLabelViewModel?.start = false
        let menuNode = childNode(withName: Identifiers.kMenu) as? SKSpriteNode
        let finalScore = menuNode?.childNode(withName: Identifiers.kFinalScoreLabel) as? SKLabelNode
        let moveAnimation = SKAction.move(to: CGPoint(x: 0, y: size.height/2.0), duration: 3.0)
        menuNode?.run(moveAnimation)
        finalScore?.text = "Your final score is: \(scoreLabelViewModel?.getCurrentScore() ?? 0)"
    }

    private func updateLives(){

        let lives = childNode(withName: Identifiers.kLivesLabel) as? SKLabelNode
        lives?.text = "Lives : \(life)"
    }

    private func startGame(){

        childNode(withName: Identifiers.kStoryBG)?.removeFromParent()
        childNode(withName: Identifiers.kWhatLabel)?.removeFromParent()
        run(SKAction.repeatForever(SKAction.sequence([SKAction.run(addBoulder), SKAction.wait(forDuration: 1.0)])))
        run(SKAction.repeatForever(SKAction.sequence([SKAction.run(addPowerUp), SKAction.wait(forDuration: 8.0)])))
        scoreLabelViewModel?.start = true
    }

    private func addBoulder(){

        let boulder = SKSpriteNode(imageNamed: "Boulder.png")
        setupFallingObject(sprite: boulder, categoryBitMask: PhysicsCategory.boulder, contactTestBitMask: PhysicsCategory.player | PhysicsCategory.laser)
    }

    private func addPowerUp(){

        let powerUp = SKSpriteNode(imageNamed: "PowerUp.png")
        setupFallingObject(sprite: powerUp, categoryBitMask: PhysicsCategory.powerUp)
    }

    private func randomPositionGenerator(left : CGFloat, right : CGFloat) -> CGFloat{

        return CGFloat(arc4random_uniform(UInt32(right - left))) + left
    }

    private func setupFallingObject(sprite : SKSpriteNode, categoryBitMask : UInt32, contactTestBitMask : UInt32 = PhysicsCategory.player){

        sprite.physicsBody = SKPhysicsBody(circleOfRadius: sprite.size.height/2.0)
        sprite.physicsBody?.isDynamic = true
        sprite.physicsBody?.categoryBitMask = categoryBitMask
        sprite.physicsBody?.contactTestBitMask = contactTestBitMask
        sprite.physicsBody?.collisionBitMask = PhysicsCategory.none

        let x = randomPositionGenerator(left:  -size.width/2.0, right: size.width/2.0 - sprite.size.width/2.0)
        sprite.position = CGPoint(x: x, y: size.height)
        addChild(sprite)

        let move = SKAction.moveTo(y: 0.0, duration: 8.0)
        let done = SKAction.removeFromParent()
        sprite.run(SKAction.sequence([move, done]))
    }

    private func handlePlayerTouch(touches : Set<UITouch>){

        for touch in touches{
            let location = touch.location(in: self)
            direction = location.x < 0.0 ? Direction.left : Direction.right
        }
    }

    private func moveSprite(){
        guard let spriteViewModel = playerSpriteViewModel, let dir = direction else {return}

        if dir == .left{
            spriteViewModel.updateSpritePosition(x: max(spriteViewModel.currentXPosition - 20.0, -size.width/2.0), direction : dir)
        }else if dir == .right{
            spriteViewModel.updateSpritePosition(x: min(spriteViewModel.currentXPosition + 20.0, size.width/2.0), direction : dir)
        }else{
            spriteViewModel.updateSpritePosition(x: spriteViewModel.currentXPosition, direction : dir)
        }
    }
}

extension GameScene : SKPhysicsContactDelegate{

    func didBegin(_ contact: SKPhysicsContact) {

        let firstBody = contact.bodyA
        let secondBody = contact.bodyB

        let bodies = [firstBody, secondBody]

        //check collision
        if (firstBody.categoryBitMask == 1 && secondBody.categoryBitMask == 2) || (firstBody.categoryBitMask == 2 && secondBody.categoryBitMask == 1){

            if let boulder = bodies.first(where: {$0.categoryBitMask == 1})?.node as? SKSpriteNode{
                boulderHit(boulder: boulder)
            }

        }else if (firstBody.categoryBitMask == 2 && secondBody.categoryBitMask == 3) || (firstBody.categoryBitMask == 3 && secondBody.categoryBitMask == 2){

            if let power = bodies.first(where: {$0.categoryBitMask == 3})?.node as? SKSpriteNode{
                powerUp(power: power)
            }
        }else if (firstBody.categoryBitMask == 1 && secondBody.categoryBitMask == 4) || (firstBody.categoryBitMask == 4 && secondBody.categoryBitMask == 1){
            if let boulder = bodies.first(where: {$0.categoryBitMask == 1})?.node as? SKSpriteNode{
                boulderDestroyed(boulder : boulder)
            }
        }
    }
}

// Load the SKScene from 'GameScene.sks'
let sceneView = SKView(frame: CGRect(x:0 , y:0, width: 640, height: 480))

if let scene = GameScene(fileNamed: "GameScene") {
    // Set the scale mode to scale to fit the window
    scene.scaleMode = .aspectFill
    scene.backgroundColor = UIColor(red: 0.0, green: 180.0/255.0, blue: 229.0/255.0, alpha: 1.0)
    // Present the scene
    sceneView.presentScene(scene)
}

PlaygroundSupport.PlaygroundPage.current.liveView = sceneView
