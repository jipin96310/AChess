//
//  GameObject.swift
//  AChess
//
//  Created by zhaoheng sun on 7/12/20.
//  Copyright © 2020 zhaoheng sun. All rights reserved.
//

import Foundation
import SceneKit
import GameplayKit
import os.log

struct CollisionMask: OptionSet {
    let rawValue: Int
    
    static let rigidBody = CollisionMask(rawValue: 1)
    static let glitterObject = CollisionMask(rawValue: 2)
    static let ball = CollisionMask(rawValue: 4)
    static let phantom = CollisionMask(rawValue: 32)    // for detecting collisions with trigger volumes
    static let triggerVolume = CollisionMask(rawValue: 64)  // trigger behavior without affecting physics
    static let catapultTeamA = CollisionMask(rawValue: 128)
    static let catapultTeamB = CollisionMask(rawValue: 256)
}

extension GKEntity {
    func components<P>(conformingTo: P.Type) -> [P] {
        return components.compactMap { $0 as? P }
    }
}

class GameObject: GKEntity {
    let objectRootNode: SCNNode
    let geometryNode: SCNNode?
    var physicsNode: SCNNode?
    var properties = [String: Any]()
    var categorize = false
    var category = ""
    var usePredefinedPhysics = false
    var isBlockObject = true
    var density: Float = 0.0
    var isAlive: Bool
    var isServer: Bool

    static var indexCounter = 0
    var index = 0
    
    // call this before loading a level, all nodes loaded will share an index since nodes always load
    // in the same order.
    static func resetIndexCounter() {
        indexCounter = 0
    }

    // init with index that can be used to replace an old node
    init(node: SCNNode, index: Int?, gamedefs: [String: Any], alive: Bool, server: Bool) {
        objectRootNode = node
        self.isAlive = alive
        
        if let index = index {
            self.index = index
        } else {
            self.index = GameObject.indexCounter
            GameObject.indexCounter += 1
        }
        
        if let geomNode = node.findNodeWithGeometry() {
            geometryNode = geomNode
        } else {
            geometryNode = nil
        }

        self.isServer = server
        super.init()

        if let physNode = node.findNodeWithPhysicsBody(),
            physNode.physicsBody != nil {
            physicsNode = physNode
        }

        // set the gameObject onto the node
        node.gameObject = self
        
        if let def = node.name {
            initGameComponents(gamedefs: gamedefs, def: def)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    // helper for common root-level property tuning parameters
    func propDouble(_ name: String) -> Double? {
        return properties[name] as? Double
    }
    func propFloat(_ name: String) -> Float? {
        return properties[name] as? Float
    }
    func propString(_ name: String) -> String? {
        return properties[name] as? String
    }
    func propBool(_ name: String) -> Bool? {
        return properties[name] as? Bool
    }
    func propInt(_ name: String) -> Int? {
        return properties[name] as? Int
    }
    func propSIMD2Float(_ name: String) -> SIMD2<Float>? {
        if let valueString = propString(name) {
            let strings = valueString.split(separator: " ")
            if strings.count >= 2 {
                if let x = Float(strings[0]),
                   let y = Float(strings[1]) {
                    return [x, y]
                }
            }
        }
        return nil
    }
    func propSIMD3Float(_ name: String) -> SIMD3<Float>? {
        if let valueString = propString(name) {
            let strings = valueString.split(separator: " ")
            if strings.count >= 3 {
                if let x = Float(strings[0]),
                   let y = Float(strings[1]),
                   let z = Float(strings[2]) {
                    return [x, y, z]
                }
            }
        }
        return nil
    }
    func propSIMD4Float(_ name: String) -> SIMD4<Float>? {
        if let valueString = propString(name) {
            let strings = valueString.split(separator: " ")
            if strings.count >= 4 {
                let x = (strings[0] as NSString).floatValue
                let y = (strings[1] as NSString).floatValue
                let z = (strings[2] as NSString).floatValue
                let w = (strings[3] as NSString).floatValue
                return [x, y, z, w]
            }
        }
        return nil
    }

    // use the original node name to determine if there are special components that we need
    func initGameComponents(gamedefs: [String: Any], def: String) {
        guard let entityDefs = gamedefs["entityDefs"] as? [String: Any] else {
            return
        }
        
        // always remove trailing integers from def name just in case class name is just a clone of something
        let digits = CharacterSet.decimalDigits
        
        var defPrefix = def
        for uni in def.unicodeScalars.reversed() {
            if digits.contains(uni) {
                defPrefix = String(defPrefix.dropLast())
            } else {
                break
            }
        }

        var baseDef = [String: Any]()
        
        // set up basedef, just in case nothing was found
        if let base = entityDefs["base"] as? [String: Any] {
            baseDef = base
            category = "base"
        }
        
        // if we have a physics body, use that as the base def
        if geometryNode != nil && physicsNode != nil {
            if let base = entityDefs["basePhysics"] as? [String: Any] {
                baseDef = base
                category = "basePhysics"
            }
        }
        
        // check up to the first underscore
        if let type = objectRootNode.typeIdentifier, let base = entityDefs[type] as? [String: Any] {
            baseDef = base
            category = type
        }
        
        // check the name without the last number
        if let base = entityDefs[defPrefix] as? [String: Any] {
            baseDef = base
            category = defPrefix
        }
        
        // now check for the actual name
        if let base = entityDefs[def] as? [String: Any] {
            baseDef = base
            category = def
        }
        
        properties = baseDef
        
        for (key, value) in baseDef {
            switch key {
                

            case "properties":
                setupProperties(value: value)
            case "category":
                setupCategory(value: value)
            case "blockObject":
                updateBlockObject(value: value)
            case "predefinedPhysics":
                updatePredefinedPhysics(value: value)
            case "density":
                updateDensity(value: value)
            default:
                os_log(.info, "Unknown component %s", key)
            }
        }
    }

  
    
    // generic properties on this object
    func setupProperties(value: Any) {
        if let properties = value as? [String: Any] {
            self.properties = properties
        }
    }
    


    
    // categories let you group like objects together under a similar container
    func setupCategory(value: Any) {
        guard let properties = value as? [String: Any],
            let enabled = properties["enabled"] as? Bool, enabled else { return }
        if let newCategory = properties["header"] as? String {
            categorize = true
            category = newCategory
        }
    }

    
    func updateBlockObject(value: Any) {
        if let doBlockObject = value as? Bool {
            isBlockObject = doBlockObject
        }
    }

    func updatePredefinedPhysics(value: Any) {
        if let predefinedPhysics = value as? Bool {
            usePredefinedPhysics = predefinedPhysics
        }
    }
    
    func updateDensity(value: Any) {
        if let density = value as? Float {
            self.density = density
        }
    }

    // load the entity definitions from the specified file
    static func loadGameDefs(file: String) -> [String: Any] {
        var gameDefs = [String: Any]()
        if let url = Bundle.main.url(forResource: file, withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                
                // strip comments out of the file with a regex
                let commentRemovalRegex = "//.*\\n\\s*|/\\*.*?\\n?.*?\\*/\\n?\\s*"
                let regex = try NSRegularExpression(pattern: commentRemovalRegex, options: [])

                var dataString = String(data: data, encoding: .utf8)!
                dataString = regex.stringByReplacingMatches(in: dataString, range: NSRange(location: 0, length: dataString.count), withTemplate: "")
    
                let dataNoComments = dataString.data(using: .utf8)!

                // now parse that
                let object = try JSONSerialization.jsonObject(with: dataNoComments, options: .allowFragments)
                
                if let dictionary = object as? [String: AnyObject] {
                    gameDefs = dictionary
                }
            } catch {
                os_log(.error, "Error!! Unable to parse %s.json with %s", file, "\(error)")
            }
        }
        
        // correct for inheritance
        guard let defs: [String: Any] = gameDefs["entityDefs"] as? [String: Any] else {
            return [String: Any]()
        }
        var newDefs = [String: Any]()
        
        // if a def has an inheritance key, apply the inheritance
        for (key, value) in defs {
            if let def = value as? [String: Any] {
                newDefs[key] = updateDefInheritance(defs: defs, def: def)
            }
        }
        gameDefs["entityDefs"] = newDefs
        
        return gameDefs
    }
    
    // search for inheritance if available, and copy those properties over, then overwrite
    static func updateDefInheritance(defs: [String: Any], def: [String: Any]) -> [String: Any] {
        var result = def
        
        if let inheritProp = def["inherit"] as? String,
        let inheritDef = defs[inheritProp] as? [String: Any] {
            result = updateDefInheritance(defs: defs, def: inheritDef)
            
            // copy new keys over top
            for (key, value) in def where key != "inherit" {
                result[key] = value
            }
        }
        
        return result
    }


  

  
}
