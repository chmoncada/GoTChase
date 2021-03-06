//
//  GameScene.swift
//  GoTChase
//
//  Created by Charles Moncada on 04/03/18.
//  Copyright © 2018 Charles Moncada. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    private let hero = SKSpriteNode(imageNamed: "hero1")
    let heroMovePointsPerSecond: CGFloat = 480
    var velocity = CGPoint.zero
    
    var lastUpdateTime: TimeInterval = 0
    var dt: TimeInterval = 0
    
    let playableRect: CGRect
    var lastTouchLocation: CGPoint?
    
    let heroRotateRadiansPerSec: CGFloat = 4.0 * π
    
    let heroAnimation: SKAction
    
    let enemyActionSound = SKAction.playSoundFileNamed("TIE.wav", waitForCompletion: false)
    let allyRescueSound: SKAction = SKAction.playSoundFileNamed("R2.wav", waitForCompletion: false)
    let enemyCollisionSound = SKAction.playSoundFileNamed("Explosion.wav", waitForCompletion: false)
    
    var invincible = false
    
    var lives = 5
    var rescueAllies = 0
    var gameOver = false
    
    let cameraNode = SKCameraNode()
    let cameraMovePointsPerSec: CGFloat = 200
    
    var cameraRect : CGRect {
        let x = cameraNode.position.x - size.width/2
            + (size.width - playableRect.width)/2
        let y = cameraNode.position.y - size.height/2
            + (size.height - playableRect.height)/2
        return CGRect(
            x: x,
            y: y,
            width: playableRect.width,
            height: playableRect.height)
    }
    
    override init(size: CGSize) {
        let maxAspectRatio: CGFloat = 16/9 // iPhone X ratio = 2.16
        let playableHeight = size.width / maxAspectRatio
        let playableMargin = (size.height - playableHeight)/2
        playableRect = CGRect(x: 0, y: playableMargin,
                              width: size.width,
                              height: playableHeight)
        
        var textures: [SKTexture] = []
        for i in  1...4 {
            textures.append(SKTexture(imageNamed: "hero\(i)"))
        }
        
        textures.append(textures[2])
        textures.append(textures[1])
        
        heroAnimation = SKAction.animate(with: textures, timePerFrame: 0.1)
        
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func debugDrawPlatableArea() {
        let shape = SKShapeNode(rect: playableRect)
        shape.strokeColor = SKColor.red
        shape.lineWidth = 4
        addChild(shape)
    }
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor.black
        
        for i in 0...1 {
            let background = backgroundNode()
            background.anchorPoint = CGPoint.zero
            background.position =
                CGPoint(x: CGFloat(i)*background.size.width, y: 0)
            background.name = "background"
            background.zPosition = -1
            addChild(background)
        }
        
        hero.position = CGPoint(x: 400, y: 400)
        
        // rotacion
        //hero.anchorPoint = .zero
        //hero.zRotation = .pi/8
        hero.run(SKAction.repeatForever(heroAnimation))
        addChild(hero)
        
        run(SKAction.repeatForever(
            SKAction.sequence([SKAction.run() { [weak self] in
                self?.spawnEnemy()
                },
                               SKAction.wait(forDuration: 4)])))
        
        run(SKAction.repeatForever(
            SKAction.sequence([SKAction.run() { [weak self] in
                self?.spawnAlly()
                },
                               SKAction.wait(forDuration: 1)])))
        
        //debugDrawPlatableArea()
        
        addChild(cameraNode)
        camera = cameraNode
        cameraNode.position = CGPoint(x: size.width/2, y: size.height/2)
        
    }
    
    override func didEvaluateActions() {
        checkCollisions()
    }
    
    func sceneTouched(touchLocation:CGPoint) {
        lastTouchLocation = touchLocation
        moveHeroToward(location: touchLocation)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard let touch = touches.first else { return }
        
        let touchLocation = touch.location(in: self)
        sceneTouched(touchLocation: touchLocation)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
       
        guard let touch = touches.first else { return }
        
        let touchLocation = touch.location(in: self)
        sceneTouched(touchLocation: touchLocation)
    }
    
    override func update(_ currentTime: TimeInterval) {
        
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        } else {
            dt = 0
        }
        lastUpdateTime = currentTime
        // print("\(dt*1000) milliseconds since last update")
        
//        if let lastTouchLocation = lastTouchLocation {
//            let diff = lastTouchLocation - hero.position
//            if diff.length() <= heroMovePointsPerSecond * CGFloat(dt) {
//                hero.position = lastTouchLocation
//                velocity = .zero
//            } else {
//                move(sprite: hero, velocity: velocity)
//                rotate(sprite: hero, direction: velocity, rotateRadiansPerSec: heroRotateRadiansPerSec)
//            }
//        }
        
        move(sprite: hero, velocity: velocity)
        rotate(sprite: hero, direction: velocity, rotateRadiansPerSec: heroRotateRadiansPerSec)
        
        boundsCheckHero()

        if lives <= 0 && !gameOver {
            gameOver = true
            print("you lose!")
            
            let gameOverScene = GameOverScene(size: size, won: false)
            gameOverScene.scaleMode = scaleMode
            
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            
            view?.presentScene(gameOverScene, transition: reveal)
        }
        
        //cameraNode.position = hero.position
        moveCamera()
    }
    
    func move(sprite: SKSpriteNode, velocity: CGPoint) {
        
        let amountToMove = velocity * CGFloat(dt)
        //print("Amount to move: \(amountToMove)")
        sprite.position += amountToMove
    }
    
    func moveHeroToward(location: CGPoint) {
        // 1 Calculate the direccion where the hero should go
        let offset = location - hero.position
        // 2 Calculate the length
        //let length = offset.length()
        
        // 3 normalize the offset vector to unit vector
        let direccion = offset.normalized()
        
        // 4 calculate the velocity using the unit vector
        velocity = direccion * heroMovePointsPerSecond
    }
    
    func boundsCheckHero() {
        let bottomLeft = CGPoint(x: cameraRect.minX, y: cameraRect.minY)
        let topRight = CGPoint(x: cameraRect.maxX, y: cameraRect.maxY)
        
        if hero.position.x <= bottomLeft.x {
            hero.position.x = bottomLeft.x
            velocity.x = abs(velocity.x)
        }
        if hero.position.x >= topRight.x {
            hero.position.x = topRight.x
            velocity.x = -velocity.x
        }
        if hero.position.y <= bottomLeft.y {
            hero.position.y = bottomLeft.y
            velocity.y = -velocity.y
        }
        if hero.position.y >= topRight.y {
            hero.position.y = topRight.y
            velocity.y = -velocity.y
        }
    }
    
    func rotate(sprite: SKSpriteNode, direction: CGPoint, rotateRadiansPerSec: CGFloat) {
        let shortest = shortestAngleBetween(angle1: sprite.zRotation, angle2: direction.angle)
        let amountToRotate = min(rotateRadiansPerSec * CGFloat(dt), abs(shortest))
        sprite.zRotation += shortest.sign() * amountToRotate
        
    }
    
    func spawnEnemy() {
        let enemy = SKSpriteNode(imageNamed: "enemy")
        enemy.name = "enemy"
        
        enemy.position = CGPoint(
            x: cameraRect.maxX + enemy.size.width/2,
            y: CGFloat.random(
                min: cameraRect.minY + enemy.size.height/2,
                max: cameraRect.maxY - enemy.size.height/2))
        enemy.zPosition = 50
        addChild(enemy)
        
        let actionMove = SKAction.moveBy(x: -(size.width + enemy.size.width), y: 0, duration: 2.0)
        let group = SKAction.group([actionMove,enemyActionSound])
        let actionRemove = SKAction.removeFromParent()
        
        enemy.run(SKAction.sequence([group, actionRemove]))
        
    }
    
    func spawnAlly() {
        
        let ally = SKSpriteNode(imageNamed: "ally")
        ally.name = "ally"
        
        ally.position = CGPoint(
            x: CGFloat.random(min: cameraRect.minX,
                              max: cameraRect.maxX),
            y: CGFloat.random(min: cameraRect.minY,
                              max: cameraRect.maxY))
        ally.zPosition = 50
        ally.setScale(0)
        addChild(ally)
        
        let appear = SKAction.scale(to: 1, duration: 0.5)
        
        ally.zRotation = -π / 16
        let leftWiggle = SKAction.rotate(byAngle: π/8, duration: 0.5)
        let rightWiggle = leftWiggle.reversed()
        let fullWiggle = SKAction.sequence([leftWiggle,rightWiggle])
        
        let scaleUp = SKAction.scale(by: 1.2, duration: 0.25)
        let scaleDown = scaleUp.reversed()
        let fullScale = SKAction.sequence([scaleUp,scaleDown, scaleUp,scaleDown])
        let group = SKAction.group([fullScale, fullWiggle])
        
        let groupWait = SKAction.repeat(group, count: 10)
        
        let disappear = SKAction.scale(to: 0, duration: 0.5)
        let removeFromParent = SKAction.removeFromParent()
        let actions = [appear,groupWait,disappear,removeFromParent]
        ally.run(SKAction.sequence(actions))
        
    }
    
    func heroHit(ally: SKSpriteNode) {
        rescueAllies += 1
        ally.removeFromParent()
        run(allyRescueSound)
        
        if rescueAllies >= 15 && !gameOver {
            gameOver = true
            print("you win!")
            
            let gameOverScene = GameOverScene(size: size, won: true)
            gameOverScene.scaleMode = scaleMode
            
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            
            view?.presentScene(gameOverScene, transition: reveal)
        }
    }
    
    func heroHit(enemy: SKSpriteNode) {
        invincible = true
        
        let blinkTimes = 10.0
        let duration = 3.0
        let blinkAction = SKAction.customAction(withDuration: duration) { node, elapsedTime in
            let slice = duration / blinkTimes
            let remainder = Double(elapsedTime).truncatingRemainder(
                dividingBy: slice)
            node.isHidden = remainder > slice / 2
        }
        let setHidden = SKAction.run() { [weak self] in
            self?.hero.isHidden = false
            self?.invincible = false
        }
        hero.run(SKAction.sequence([blinkAction, setHidden]))
        run(enemyCollisionSound)
        
        lives -= 1
    }
    
    func checkCollisions() {
        var hitAllies: [SKSpriteNode] = []
        enumerateChildNodes(withName: "ally") { node, _ in
            let ally = node as!SKSpriteNode
            if ally.frame.intersects(self.hero.frame) {
                hitAllies.append(ally)
            }
        }
        
        for ally in hitAllies {
            heroHit(ally: ally)
        }
        
        if invincible { return }
        
        var hitEnemies: [SKSpriteNode] = []
        enumerateChildNodes(withName: "enemy") { node, _ in
            let enemy = node as!SKSpriteNode
            if enemy.frame.intersects(self.hero.frame) {
                hitEnemies.append(enemy)
            }
        }
        
        for enemy in hitEnemies {
            heroHit(enemy: enemy)
        }
    }
    
    func backgroundNode() -> SKSpriteNode {

        let backgroundNode = SKSpriteNode()
        backgroundNode.anchorPoint = CGPoint.zero
        backgroundNode.name = "background"
        
        let background1 = SKSpriteNode(imageNamed: "background1")
        background1.anchorPoint = CGPoint.zero
        background1.position = CGPoint(x: 0, y: 0)
        backgroundNode.addChild(background1)
        
        let background2 = SKSpriteNode(imageNamed: "background2")
        background2.anchorPoint = CGPoint.zero
        background2.position =
            CGPoint(x: background1.size.width, y: 0)
        backgroundNode.addChild(background2)
        
        backgroundNode.size = CGSize(
            width: background1.size.width + background2.size.width,
            height: background1.size.height)
        return backgroundNode
    }
    
    func moveCamera() {
        let backgroundVelocity =
            CGPoint(x: cameraMovePointsPerSec, y: 0)
        let amountToMove = backgroundVelocity * CGFloat(dt)
        cameraNode.position += amountToMove
        
        enumerateChildNodes(withName: "background") { node, _ in
            let background = node as! SKSpriteNode
            if background.position.x + background.size.width <
                self.cameraRect.origin.x {
                background.position = CGPoint(
                    x: background.position.x + background.size.width*2,
                    y: background.position.y)
            }
        }
    }
}
