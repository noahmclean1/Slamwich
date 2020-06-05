//
//  GameData.swift
//  Slamwich
//
//  Created by Noah McLean on 4/25/20.
//  Copyright © 2020 Noah McLean. All rights reserved.
//

import Foundation
import Firebase

// Will be used for Firebase
struct PlayerData: Codable {
    let id: String
    let name: String
    var score: Int
}

// Card representation for playing
struct Card: Codable {
    let name: String
    let value: Double
    let description: String
    let type: String
    //let picture: Image
    
    init(fromDictionary dic: NSDictionary, withType type: String) throws {
        guard let name = dic.value(forKey: "name") as? String else {throw GameDataError.BadInit}
        guard let value = dic.value(forKey: "value") as? String else {throw GameDataError.BadInit}
        guard let description = dic.value(forKey: "flavor") as? String else {throw GameDataError.BadInit}
        
        self.name = name
        self.value = Double(value)!
        self.description = description
        self.type = type
    }
}

// Combo representation for playing
struct Combo: Equatable {
    let name: String
    let multiplier: Double
    let cards: [String] // Any specific cards we need (by name)
    let types: [String] // Any specific types we need
    
    init(fromDictionary dic: NSDictionary, withName name: String) throws {
        guard let mult = dic.value(forKey: "multiplier") as? Double else {throw GameDataError.BadInit}
        guard let reqs = dic.value(forKey: "reqs") as? [String] else {throw GameDataError.BadInit}
        
        // Change underscores in the plist to spaces
        self.name = name.replacingOccurrences(of: "_", with: " ")
        self.multiplier = mult
        
        // Determine whether we need types or cards for the combo
        var cs = [String]()
        var ts = [String]()
        for req in reqs {
            // Check for types
            let lowerBound = req.index(req.startIndex, offsetBy: 0)
            let upperBound = req.index(req.startIndex, offsetBy: 1)
            if req[lowerBound...upperBound] == "t:" {
                let typeLowerBound = req.index(req.startIndex, offsetBy: 2)
                
                
                
                ts.append(String(req[typeLowerBound...]).replacingOccurrences(of: "_", with: " "))
            }
            else {
                cs.append(req.replacingOccurrences(of: "_", with: " "))
            }
        }
        self.cards = cs
        self.types = ts
    }
}

// Will be used in Firebase
struct Turn: Codable{
    let taker: String
    let played: Card
}

// Also to be used in Firebase updating loop
struct GameData: Codable {
    var player1: PlayerData
    var player2: PlayerData
    var turns: [Turn]
    var whoseTurn: Int

    init(snapshot: DataSnapshot) throws {
        if let val = snapshot.value as? [String: Any] {
            guard let p1 = val["player1"] as? PlayerData else {throw GameDataError.BadInit}
            guard let p2 = val["player2"] as? PlayerData else {throw GameDataError.BadInit}
            guard let wt = val["whoseTurn"] as? Int else {throw GameDataError.BadInit}
            if let turns = val["turns"] as? [Turn] {
                self.turns = turns
            }
            else {turns = []}
            player1 = p1
            player2 = p2
            whoseTurn = wt
        } else {
            throw GameDataError.BadInit
        }
    }
}

// Notifies us that a networking error occurred
enum GameDataError: Error {
    case BadInit
}
