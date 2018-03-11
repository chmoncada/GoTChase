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
    private let hero = SKSpriteNode(imageNamed: "hero")
    let heroMovePointsPerSecond: CGFloat = 480
    var velocity = CGPoint.zero
    
    var lastUpdateTime: TimeInterval = 0
    var dt: TimeInterval = 0
    
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
        
        addChild(hero)
    }
    
    
    func touchDown(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.green
            self.addChild(n)
        }
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.blue
            self.addChild(n)
        }
    }
    
    func touchUp(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.red
            self.addChild(n)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let label = self.label {
            label.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
        }
        
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        } else {
            dt = 0
        }
        lastUpdateTime = currentTime
        print("\(dt*1000) milliseconds since last update")
        
        move(sprite: hero, velocity: CGPoint(x: heroMovePointsPerSecond, y: 0))
    }
    
    func move(sprite: SKSpriteNode, velocity: CGPoint) {
        
        let amountToMove = CGPoint(x: velocity.x * CGFloat(dt),
                                   y: velocity.y * CGFloat(dt))
        print("Amount to move: \(amountToMove)")
        
        sprite.position = CGPoint(
            x: sprite.position.x + amountToMove.x,
            y: sprite.position.y + amountToMove.y)
    }
    
}
