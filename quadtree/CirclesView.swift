//
//  CirclesView.swift
//  quadtree
//
//  Created by Jason Aeschliman on 11/26/15.
//  Copyright © 2015 Jason Aeschliman. All rights reserved.
//

import AppKit

extension CGPoint {
    func dot(other: CGPoint) -> CGFloat {
        return (self.x * other.x) + (self.y * other.y)
    }
    func sub(other: CGPoint) -> CGPoint {
        return CGPoint(x: self.x - other.x, y: self.y - other.y)
    }
    func add(other: CGPoint) -> CGPoint {
        return CGPoint(x: self.x + other.x, y: self.y + other.y)
    }
    func mag() -> CGFloat {
        return hypot(self.x, self.y)
    }
    func heading() -> CGFloat {
        return atan2(self.y, self.x)
    }
    func mul(n: CGFloat) -> CGPoint {
        return CGPoint(x: self.x * n, y: self.y * n)
    }
    
}

class Circle {
    
    init(radius: CGFloat, position: CGPoint, delta: CGPoint) {
        self.radius = radius
        self.position = position
        self.delta = delta
        self.mass = 0.1 * radius
    }
    
    let mass : CGFloat
    let radius : CGFloat
    var position : CGPoint
    var delta : CGPoint
    
    func collidesWith(other: Circle) -> Bool {
        let dx = other.position.x - self.position.x
        let dy = other.position.y - self.position.y
        let a = dx * dx
        let b = dy * dy
        let c = sqrt(a + b)
        return c < (other.radius + self.radius)
    }
    
    var drawFill = false
    
    var frame : CGRect {
        let d = radius * 2
        return CGRect(x: position.x - radius, y: position.y - radius, width: d, height: d)
    }
    
    func draw() {
        NSBezierPath(ovalInRect: frame).stroke()
        if drawFill {
            NSColor.cyanColor().setFill()
        } else {
            NSColor.whiteColor().setFill()
        }
        NSBezierPath(ovalInRect: frame).fill()
    }
    
    func update(world : CGSize) {
        var x = position.x + delta.x
        var y = position.y + delta.y
        
        var hit = false
        
        if x < 0 {
            x = 0
            delta.x *= -1
            hit = true
        } else if x > world.width {
            x = world.width
            delta.x *= -1
            hit = true
        }
        
        if y < 0 {
            y = 0
            delta.y *= -1
            hit = true
        } else if y > world.height {
            y = world.height
            delta.y *= -1
            hit = true
        }
        
        //damp velocity to counter crappy physics
        if hit {
            delta = delta.mul(0.8)
        }
        
        position = CGPoint(x: x, y: y)
        drawFill = hit
    }
    
    func collide(other : Circle) {
        // cribbed from: https://processing.org/examples/circlecollision.html
        
        let b = other.position.sub(self.position)
        let theta = b.heading()
        let sine = sin(theta)
        let cosine = cos(theta)
        
        var bTemp = [CGPointZero, CGPointZero]
        
        bTemp[1].x = cosine * b.x + sine * b.y
        bTemp[1].y = cosine * b.y - sine * b.x
        
        var vTemp = [CGPointZero, CGPointZero]
        
        vTemp[0].x = cosine * delta.x + sine * delta.y
        vTemp[0].y = cosine * delta.y + sine * delta.x
        vTemp[1].x = cosine * other.delta.x + sine * other.delta.y
        vTemp[1].y = cosine * other.delta.y + sine * other.delta.x
        
        var vFinal = [CGPointZero, CGPointZero]
        
        vFinal[0].x = ((mass - other.mass) * vTemp[0].x + 2 * other.mass * vTemp[1].x) / (mass + other.mass)
        vFinal[0].y = vTemp[0].y
        
        vFinal[1].x = ((other.mass - mass) * vTemp[1].x + 2 * mass * vTemp[0].x) / (mass + other.mass)
        vFinal[1].y = vTemp[1].y
        
        //hack to avoid clumping
        bTemp[0].x += vFinal[0].x
        bTemp[1].x += vFinal[1].x
        //bTemp[0].y += vFinal[0].y
        //bTemp[1].y += vFinal[1].y
        
        var bFinal = [CGPointZero, CGPointZero]
        
        bFinal[0].x = cosine * bTemp[0].x - sine * bTemp[0].y
        bFinal[0].y = cosine * bTemp[0].y + sine * bTemp[0].x
        bFinal[1].x = cosine * bTemp[1].x - sine * bTemp[1].y
        bFinal[1].y = cosine * bTemp[1].y + sine * bTemp[1].x
        
        other.position = position.add(bFinal[1])
        position = position.add(bFinal[0])
        
        let vx = cosine * vFinal[0].x - sine * vFinal[0].y
        let vy = cosine * vFinal[0].y + sine * vFinal[0].x
        let ovx = cosine * vFinal[1].x - sine * vFinal[1].y
        let ovy = cosine * vFinal[1].y + sine * vFinal[1].x
        
        delta = CGPoint(x: vx, y: vy)
        other.delta = CGPoint(x: ovx, y: ovy)
    }
    
    var hit = false
}


class CirclesView : NSView {
    
    var circles = [Circle]()
    let qtree   = QTree()
    
    override func awakeFromNib() {
        let count = 360
        let max_radius : Int32 = 15
        let min_radius : Int32 = 5
        
        for _ in 0..<count {
            let r = CGFloat((rand() % (max_radius - min_radius)) + min_radius)
            let x = CGFloat(rand()) % bounds.width
            let y = CGFloat(rand()) % bounds.height
            let mx = 2
            let dx = CGFloat((rand() % Int32(2 * mx)) - mx)
            let dy = CGFloat((rand() % Int32(2 * mx)) - mx)
            
            let d = CGPoint(x: dx, y: dy)
            
            let c = Circle(radius: r, position: CGPoint(x: x, y: y), delta: d)
            circles.append(c)
        }
        
        circles.append(Circle(radius: 35, position: CGPoint(x:bounds.midX, y:bounds.midY), delta: CGPointZero))
        
        let timer = NSTimer(timeInterval: 0.03, target: self, selector: "tick", userInfo: nil, repeats: true)
        NSRunLoop.currentRunLoop().addTimer(timer, forMode: NSDefaultRunLoopMode)
    }
    
    func tick() {
        
        qtree.reset(self.bounds)
        
        for c in circles {
            c.update(self.bounds.size)
            c.drawFill = false
            qtree.insert(c)
        }
        
        qtree.root.possibleCollisions {
            a, b in
            let a = a as! Circle
            let b = b as! Circle
            
            if a.collidesWith(b) {
                a.collide(b)
                a.drawFill = true
                b.drawFill = true
            }
        }
        
        self.needsDisplay = true
    }
    
    override func drawRect(dirtyRect: NSRect) {
        NSColor.whiteColor().setFill()
        NSRectFill(dirtyRect)
        NSColor.cyanColor().setFill()
        NSColor.blackColor().setStroke()
        
        qtree.root.draw()
        
        NSColor.redColor().setStroke()
        
        qtree.root.possibleCollisions {
            a, b in
            let a = a as! Circle
            let b = b as! Circle
            
            let path = NSBezierPath()
            path.moveToPoint(a.position)
            path.lineToPoint(b.position)
            path.stroke()
        }
        
        for c in circles {
            c.draw()
        }
        
    }
}




