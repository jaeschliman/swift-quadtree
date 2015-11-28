//
//  qtree.swift
//  quadtree
//
//  Created by Jason Aeschliman on 11/26/15.
//  Copyright © 2015 Jason Aeschliman. All rights reserved.
//

import CoreGraphics
import AppKit

extension CGRect {
    var rightEdge : CGFloat {
        return self.origin.x + self.width
    }
    var leftEdge : CGFloat {
        return self.origin.x
    }
    var topEdge : CGFloat {
        return self.origin.y
    }
    var bottomEdge : CGFloat {
        return self.origin.y + self.height
    }
}

protocol P {
    var position : CGPoint { get }
    var frame    : CGRect  { get }
}

extension Circle : P {}

private let max = 5

struct Node {
    let width  : CGFloat
    let height : CGFloat
    let center : CGPoint
    
    var split : Bool = false
    var items : [P] = []
    var subnodes : [Node] = []
    
    var a : Node { get { return subnodes[0] } set(n) { subnodes[0] = n } }
    var b : Node { get { return subnodes[1] } set(n) { subnodes[1] = n } }
    var c : Node { get { return subnodes[2] } set(n) { subnodes[2] = n } }
    var d : Node { get { return subnodes[3] } set(n) { subnodes[3] = n } }
    
    func hasRoom() -> Bool {
        if width < 5 || height < 5 {
            return true
        }
        
        return items.count < max
    }
    
    func draw() {
        if split {
            let w = width / 2.0
            let h = height / 2.0
            
            do {
                let path = NSBezierPath()
                path.moveToPoint(CGPoint(x : center.x + 0, y : center.y + h))
                path.lineToPoint(CGPoint(x : center.x + 0, y : center.y - h))
                path.stroke()
            }
            
            do {
                let path = NSBezierPath()
                path.moveToPoint(CGPoint(x : center.x + w, y : center.y + 0))
                path.lineToPoint(CGPoint(x : center.x - w, y : center.y + 0))
                path.stroke()
            }
            
            for subnode in subnodes {
                subnode.draw()
            }
        }
    }
    
    /*
    a b
    c d
    */
    mutating func insert(item : P) {
        if !split && hasRoom() {
            items.append(item)
            return
        }
        
        if !split {
            items.append(item)
            splitNode()
            return
        }
        
        let f = item.frame
        
        if f.rightEdge < center.x {
            if f.bottomEdge < center.y {
                //a
                a.insert(item)
            } else if f.topEdge > center.y {
                //c
                c.insert(item)
            } else {
                a.insert(item)
                c.insert(item)
                //items.append(item)
            }
        } else if f.leftEdge > center.x {
            if f.bottomEdge < center.y {
                //b
                b.insert(item)
            } else if f.topEdge > center.y {
                //d
                d.insert(item)
            } else {
                b.insert(item)
                d.insert(item)
                //items.append(item)
            }
        } else {
            if f.bottomEdge < center.y {
                //a b
                a.insert(item)
                b.insert(item)
            } else if f.topEdge > center.y {
                // c d
                c.insert(item)
                d.insert(item)
            } else {
                //items.append(item)
                a.insert(item)
                b.insert(item)
                c.insert(item)
                d.insert(item)
            }
        }
        
        
        /*let p = item.position
        
        switch (p.x < center.x, p.y < center.y){
        case (true,  true):  a.insert(item)
        case (true,  false): c.insert(item)
        case (false, true):  b.insert(item)
        case (false, false): d.insert(item)
        } */
        
    }
    
    func combineWith(other : P, @noescape block: (P,P)->()) {
        for item in items {
            block(other, item)
        }
        guard split else { return }
        a.combineWith(other, block: block)
        b.combineWith(other, block: block)
        c.combineWith(other, block: block)
        d.combineWith(other, block: block)
    }
    
    func possibleCollisions(@noescape block: (P,P)->()) {
        for i in 0..<items.count {
            let outer = items[i]
            for j in (i+1)..<items.count {
                let inner = items[j]
                block(outer, inner)
            }
            if split {
                a.combineWith(outer, block: block)
                b.combineWith(outer, block: block)
                c.combineWith(outer, block: block)
                d.combineWith(outer, block: block)
            }
        }
        if split {
            a.possibleCollisions(block)
            b.possibleCollisions(block)
            c.possibleCollisions(block)
            d.possibleCollisions(block)
        }
    }
    
    
    func doItems(p : CGPoint, block: ((P) -> ())) {
        
        items.forEach(block)
        
        if !split {
            return
        }
        
        if p.x < center.x {
            if p.y < center.y {
                //a
                a.doItems(p, block: block)
            } else {
                //c
                c.doItems(p, block: block)
            }
        } else {
            if p.y < center.y {
                //b
                b.doItems(p, block: block)
            } else {
                //d
                d.doItems(p, block: block)
            }
        }
    }
    
    mutating func splitNode() {
        guard split == false else {
            fatalError("what???")
        }
        split = true
        
        let w = width / 4.0
        let h = height / 4.0
        
        let ca = CGPoint(x: center.x - w, y: center.y - h)
        let cb = CGPoint(x: center.x + w, y: center.y - h)
        let cc = CGPoint(x: center.x - w, y: center.y + h)
        let cd = CGPoint(x: center.x + w, y: center.y + h)
        
        let w2 = width / 2.0
        let h2 = height / 2.0
        subnodes.append(Node(width: w2, height: h2, center: ca, split: false, items: [], subnodes: []))
        subnodes.append(Node(width: w2, height: h2, center: cb, split: false, items: [], subnodes: []))
        subnodes.append(Node(width: w2, height: h2, center: cc, split: false, items: [], subnodes: []))
        subnodes.append(Node(width: w2, height: h2, center: cd, split: false, items: [], subnodes: []))
        
        let previous = items
        items.removeAll()
        for item in previous {
            insert(item)
        }
    }
}

class QTree {
    var root : Node = Node(width: 0, height: 0, center: CGPointZero, split: false, items: [], subnodes: [])
    
    func reset(rect : CGRect) {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        root = Node(width: rect.width, height: rect.height, center: center, split: false, items: [], subnodes: [])
    }
    
    func insert(item : P) {
        root.insert(item)
    }
    
}

