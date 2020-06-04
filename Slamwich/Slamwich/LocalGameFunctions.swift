//
//  LocalGameFunctions.swift
//  Slamwich
//
//  Created by Noah McLean on 5/21/20.
//  Copyright © 2020 Noah McLean. All rights reserved.
//

import Foundation

// MARK: - Constants
let typeRatio = ["bread":30,
                 "cheese":15,
                 "meat":20,
                 "veggie":15,
                 "condiment":8,
                 "fruit":6,
                 "other":6]

// All cards defined for the game
var cards: NSDictionary?

// All combos defined for the game
var combos: [Combo]?

// MARK: - Statuses
var gameInProgress = false

// MARK: - Deck Functions
// Generate a deck of 100 cards for playing
func createDeck() -> [Card] {
    if cards == nil {
        readInCards()
    }
        
    var deck = [Card]()
    
    // Generate the cards
    for (type, count) in typeRatio {
        for _ in 0...count {
            let card = generateCard(fromType: type)
            if card == nil {
                print("ERROR: createDeck - bad card")
                return []
            }
            deck.append(card!)
        }
    }
    
    return deck
}

// Read in the cards from a plist
func readInCards() {
    if let path = Bundle.main.path(forResource: "cards", ofType: "plist") {
        if let cs = NSMutableDictionary(contentsOfFile: path) {
            for (_, list) in cs {
                if let l = list as? [NSDictionary] {
                    for cardDetails in l {
                        
                        // Change underscores in the plist to spaces
                        let unformatted = cardDetails.value(forKey: "name") as! String
                        cardDetails.setValue(unformatted.replacingOccurrences(of: "_", with: " "), forKey: "name")
                            
                        // Remove quotes and garbage from the flavor text
                        let flavor = cardDetails.value(forKey: "flavor") as! String
                        cardDetails.setValue(flavor.replacingOccurrences(of: "\"|\n", with: "", options: .regularExpression), forKey: "flavor")
                    }
                }
            }
            cards = cs
            return
            
        }
    }
    print("ERROR: readInCards")
}

// Generate 1 card randomly
func generateCard(fromType type: String) -> Card? {
    let cs = cards!
    let cardsInType = cs[type] as! [NSDictionary]
    let selectedCard = cardsInType.randomElement()!

    return try? Card(fromDictionary: selectedCard, withType: type)
}


// MARK: - Combo Functions

func readInCombos() {
    var compiledList = [Combo]()
    if let path = Bundle.main.path(forResource: "combos", ofType: "plist") {
        if let cs = NSMutableDictionary(contentsOfFile: path) {
            for (name, vals) in cs {
                if let dic = vals as? NSDictionary {
                    if let newCombo = try? Combo(fromDictionary: dic, withName: name as! String) {
                        compiledList.append(newCombo)
                    }
                }
            }
            combos = compiledList
        }
    }
}

func comboIsValid(_ combo: Combo, sandwich: [Card]) -> Bool {
    // Tally up the requirements
    var cardsAndTypes = [String: Int]()
    for cardName in combo.cards {
        if let number = cardsAndTypes[cardName]{
            cardsAndTypes[cardName] = number + 1
        }
        else {
            cardsAndTypes[cardName] = 1
        }
    }
    for typeName in combo.types {
        if let number = cardsAndTypes[typeName] {
            cardsAndTypes[typeName] = number + 1
        }
        else {
            cardsAndTypes[typeName] = 1
        }
    }
    
    // Traverse the sandwich
    for card in sandwich {
        if let num = cardsAndTypes[card.name] {
            cardsAndTypes[card.name] = max(num-1, 0)
        }
        else if let num = cardsAndTypes[card.type] {
            cardsAndTypes[card.type] = max(num-1, 0)
        }
    }
    
    // Check if all requirements are satisfied
    for (_,val) in cardsAndTypes {
        if val > 0 {
            return false
        }
    }
    return true
}

func applyCombo(_ combo: Combo, sandwich: [Card], multipliers mults: inout [Double]) {
    // Tally up the bonuses
    var cardsAndTypes = [String: Int]()
    for cardName in combo.cards {
        if let number = cardsAndTypes[cardName]{
            cardsAndTypes[cardName] = number + 1
        }
        else {
            cardsAndTypes[cardName] = 1
        }
    }
    for typeName in combo.types {
        if let number = cardsAndTypes[typeName] {
            cardsAndTypes[typeName] = number + 1
        }
        else {
            cardsAndTypes[typeName] = 1
        }
    }
    
    // Apply the bonuses
    for (i, card) in sandwich.enumerated() {
        if let num = cardsAndTypes[card.name] {
            cardsAndTypes[card.name] = max(num-1, 0)
            mults[i] *= combo.multiplier
        }
        else if let num = cardsAndTypes[card.type] {
            cardsAndTypes[card.type] = max(num-1, 0)
            mults[i] *= combo.multiplier
        }
    }
}

// Check what combos will be new if the card is added
func newCombosFrom(_ sandwich: [Card], newCard card: Card, _ currentCombos: [Combo]) -> [Combo] {
    if let cs = combos {
        var newCombos = [Combo]()
        let newSandwich = sandwich + [card]
        for c in cs {
            if !currentCombos.contains(c) {
                if comboIsValid(c, sandwich: newSandwich) {
                    newCombos.append(c)
                }
            }
        }
        
        return newCombos
    }
    return []
}

func combosToString(_ combos: [Combo]) -> String {
    var str = ""
    if combos.count == 0 {
        str = "No combos"
    }
    for c in combos {
        str += "\(c.name)\n"
    }
    return str
}

// MARK: - Hand Functions

// If there's no bread active, check if the game is playable
func isGameStuck(hand: [Card]) -> Bool {
    //print(hand)
    for card in hand {
        if card.type == "bread" {
            return false
            
        }
    }
    return true
}

// MARK: - Gameplay Functions

func validPlay(card: Card, sandwich: [Card]) -> Bool {
    if sandwich.isEmpty && card.type != "bread" {
        return false
    }
    return true
}

func generateBread() -> Card {
    if cards == nil {
        readInCards()
    }
    
    let cs = cards!
    let cardsInType = cs.object(forKey: "bread") as! [NSDictionary]
    let card = cardsInType.randomElement()!
    return try! Card(fromDictionary: card, withType: "bread")
}

func scoreSandwich(_ sandwich: [Card]) -> (Double,[Combo]) {
    // Tally up each applicable combo & aggregate the multipliers
    var multipliers = [Double](repeating: 1.0, count: sandwich.count)
    var cs = [Combo]()
    
    for combo in combos! {
        if comboIsValid(combo, sandwich: sandwich) {
            applyCombo(combo, sandwich: sandwich, multipliers: &multipliers)
            cs.append(combo)
        }
    }
    
    // Matching bread gives extra points!
    if sandwich[0].name == sandwich.last!.name && sandwich.count > 1 {
        multipliers[0] *= 4.0
    }
    
    // With multipliers sum up the sandwich value
    var total = 0.0
    for (i, card) in sandwich.enumerated() {
        total += Double(card.value) * multipliers[i]
    }
    return (total, cs)
}
