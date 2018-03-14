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
        
        // create a sprite
        let background = SKSpriteNode(imageNamed: "background1")
        background.zPosition = -1
        addChild(background)
        //background.anchorPoint = .zero
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        
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
                               SKAction.wait(forDuration: 2)])))
        
        run(SKAction.repeatForever(
            SKAction.sequence([SKAction.run() { [weak self] in
                self?.spawnAlly()
                },
                               SKAction.wait(forDuration: 1)])))
        
        debugDrawPlatableArea()
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
        
        if let lastTouchLocation = lastTouchLocation {
            let diff = lastTouchLocation - hero.position
            if diff.length() <= heroMovePointsPerSecond * CGFloat(dt) {
                hero.position = lastTouchLocation
                velocity = .zero
            } else {
                move(sprite: hero, velocity: velocity)
                rotate(sprite: hero, direction: velocity, rotateRadiansPerSec: heroRotateRadiansPerSec)
            }
        }
        
        boundsCheckHero()

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
        let bottomLeft = CGPoint(x: 0, y: playableRect.minY)
        let topRight = CGPoint(x: size.width, y: playableRect.maxY)
        
        if hero.position.x <= bottomLeft.x {
            hero.position.x = bottomLeft.x
            velocity.x = -velocity.x
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
            x: size.width + enemy.size.width/2,
            y: CGFloat.random(
                min: playableRect.minY + enemy.size.height/2,
                max: playableRect.maxY - enemy.size.height/2))
        addChild(enemy)
        
        let actionMove = SKAction.moveTo(x: -enemy.size.width/2, duration: 2)
        let actionSound = SKAction.playSoundFileNamed("TIE.wav", waitForCompletion: false)
        let group = SKAction.group([actionMove,actionSound])
        let actionRemove = SKAction.removeFromParent()
        
        enemy.run(SKAction.sequence([group, actionRemove]))
        
    }
    
    func spawnAlly() {
        
        let ally = SKSpriteNode(imageNamed: "ally")
        ally.name = "ally"
        
        ally.position = CGPoint(
            x: CGFloat.random(min: playableRect.minX,
                              max: playableRect.maxX),
            y: CGFloat.random(min: playableRect.minY,
                              max: playableRect.maxY))
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
        ally.removeFromParent()
        run(SKAction.playSoundFileNamed("R2.wav", waitForCompletion: false))
    }
    
    func heroHit(enemy: SKSpriteNode) {
        enemy.removeFromParent()
        run(SKAction.playSoundFileNamed("Explosion.wav", waitForCompletion: false))
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
}
