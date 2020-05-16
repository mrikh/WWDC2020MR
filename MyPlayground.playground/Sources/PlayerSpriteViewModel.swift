import Foundation
import SpriteKit

public class PlayerSpriteViewModel{

    private var playerSprite : SKSpriteNode?

    private var allowMovement = false

    //actions
    private var idleAnimation : SKAction?
    private var leftAnimation : SKAction?
    private var rightAnimation : SKAction?
    private var laserAnimation : SKAction?

    public var currentXPosition : CGFloat{
        return playerSprite?.position.x ?? 0.0
    }

    public convenience init(playerSprite : SKSpriteNode?) {

        self.init()
        self.playerSprite = playerSprite

        var textures : [SKTexture] = []
        for i in 1...4{
            textures.append(SKTexture(imageNamed: "Idle\(i)"))
        }
        idleAnimation = SKAction.animate(with: textures, timePerFrame: 0.12)
        playerSprite?.run(SKAction.repeatForever(idleAnimation!), withKey : "idle")

        var leftTextures : [SKTexture] = []
        for i in 1...9{
            leftTextures.append(SKTexture(imageNamed: "Left\(i)"))
        }
        leftAnimation = SKAction.animate(with: leftTextures, timePerFrame: 0.12)

        var rightTextures : [SKTexture] = []
        for i in 1...9{
            rightTextures.append(SKTexture(imageNamed: "Right\(i)"))
        }
        rightAnimation = SKAction.animate(with: rightTextures, timePerFrame: 0.12)

        var laserTextures : [SKTexture] = []
        for i in 1...8{
            laserTextures.append(SKTexture(imageNamed: "Laser\(i)"))
        }
        for i in stride(from: 8, to: 3, by: -1) {
            laserTextures.append(SKTexture(imageNamed: "Laser\(i)"))
        }
        laserAnimation = SKAction.animate(with: laserTextures, timePerFrame: 0.12)

        let playerSize = playerSprite?.size ?? CGSize.zero
        playerSprite?.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: playerSize.width/2.0, height: playerSize.height))
        playerSprite?.physicsBody?.isDynamic = true
        playerSprite?.physicsBody?.categoryBitMask = PhysicsCategory.player
        playerSprite?.physicsBody?.contactTestBitMask = PhysicsCategory.boulder
        playerSprite?.physicsBody?.collisionBitMask = PhysicsCategory.none
        playerSprite?.physicsBody?.usesPreciseCollisionDetection = true
    }

    public func updateSpritePosition(x : CGFloat, direction : Direction){

        if allowMovement {return}

        playerSprite?.position.x = x

        if direction == .right{
            if let animation = rightAnimation, playerSprite?.action(forKey: "right") == nil{
                playerSprite?.removeAllActions()
                playerSprite?.run(SKAction.repeatForever(animation), withKey: "right")
            }
        }else if direction == .left{
            if let animation = leftAnimation, playerSprite?.action(forKey: "left") == nil{
                playerSprite?.removeAllActions()
                playerSprite?.run(SKAction.repeatForever(animation), withKey: "left")
            }
        }else{
            if let animation = idleAnimation, playerSprite?.action(forKey: "idle") == nil{
                playerSprite?.removeAllActions()
                playerSprite?.run(SKAction.repeatForever(animation), withKey : "idle")
            }
        }
    }

    public func startLaser(laserNode : SKSpriteNode?){

        guard let animation = laserAnimation else {return}
        var laserTextures : [SKTexture] = []
        for i in 1...6{
            laserTextures.append(SKTexture(imageNamed: "Beam\(i)"))
        }
        let beamAnimation = SKAction.animate(with: laserTextures, timePerFrame: 0.1)

        allowMovement = true
        playerSprite?.removeAllActions()
        playerSprite?.run(animation, completion: { [weak self] in
            self?.allowMovement = false
        })
        laserNode?.position.x = (playerSprite?.position.x ?? 0.0) + 5.0
        laserNode?.physicsBody?.categoryBitMask = PhysicsCategory.laser
        laserNode?.run(SKAction.sequence([SKAction.fadeIn(withDuration: 0.2), beamAnimation, SKAction.rotate(byAngle: CGFloat(Double.pi * 0.999), duration: 0.5), SKAction.rotate(byAngle: -CGFloat(Double.pi * 0.999), duration: 0.5),  SKAction.fadeOut(withDuration: 0.1)]), completion: {
            laserNode?.physicsBody?.categoryBitMask = PhysicsCategory.none
        })
    }

    public func animateRight(_ completion : (()->())?){

        guard let animation = rightAnimation, let idleAnimation = self.idleAnimation else {return}
        playerSprite?.removeAllActions()
        playerSprite?.run(SKAction.repeatForever(animation))
        playerSprite?.run(SKAction.moveBy(x: 300.0, y: 0.0, duration: 1.8), completion: { [weak self] in
            self?.playerSprite?.removeAllActions()
            self?.playerSprite?.run(SKAction.repeatForever(idleAnimation))
            completion?()
        })
    }

    public func animateLeft(_ completion : (()->())?){

        guard let animation = leftAnimation, let idleAnimation = self.idleAnimation else {return}

        playerSprite?.removeAllActions()
        let finalAction = SKAction.moveBy(x: -300.0, y: 0.0, duration: 1.8)
        playerSprite?.run(SKAction.sequence([SKAction.wait(forDuration: 1.2), finalAction]), completion: { [weak self] in
            self?.playerSprite?.removeAllActions()
            self?.playerSprite?.run(SKAction.repeatForever(idleAnimation))
            completion?()
        })

        playerSprite?.run(SKAction.sequence([SKAction.wait(forDuration: 1.2), SKAction.repeatForever(animation)]))
    }
}
