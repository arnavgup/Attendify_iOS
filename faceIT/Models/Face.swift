//
//  Face.swift
//  Created by Michael Ruhl on 17.08.17.
//  Copyright © 2017 NovaTec GmbH. All rights reserved.
//  Updated by Arnav Gupta
//  Last updated: December 6th, 2018

import Foundation
import ARKit

// MARK: Face

class Face {
  
    /// name ID (ex. George Yao)
    let name: String
  
    /// node (Used by AR framework)
    let node: SCNNode
  
    /// hidden (Used by AR framework)
    var hidden: Bool {
        get{
            return node.opacity != 1
        }
    }
  
    /// timestamp (always latest)
    var timestamp: TimeInterval {
        didSet {
            updated = Date()
        }
    }
  
    /// updated (last updated)
    private(set) var updated = Date()
  
    /**
     Initializes a new face, for each face that is recognized
     by ml model.
   
     - Parameters:
     - name: The full name of the person
     - node: Nodes pointers refering to that person in 3-D space
     - timestamp: The timestamp of initialization/face recognition
   
     - Returns: A face used within the AR framework
     */
    init(name: String, node: SCNNode, timestamp: TimeInterval) {
        self.name = name
        self.node = node
        self.timestamp = timestamp
    }
}

extension Date {
    func isAfter(seconds: Double) -> Bool {
        let elapsed = Date.init().timeIntervalSince(self)
        
        if elapsed > seconds {
            return true
        }
        return false
    }
}
