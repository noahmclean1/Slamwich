//
//  AI.swift
//  Slamwich
//
//  Created by Noah McLean on 5/22/20.
//  Copyright © 2020 Noah McLean. All rights reserved.
//

import Foundation

// TODO NSOperation

func pickACardAI(hand: [Card], sandwichInProgress: [Card]) -> Int {
    // Simple optimizer to pick best card
    var (bestScore, bestIndex) = (-10000.0,-1)
    for (i,card) in hand.enumerated() {
        
        if !validPlay(card: card, sandwich: sandwichInProgress) {
            continue
        }
        
        // Simulate placing it
        let (score, _)  = scoreSandwich(sandwichInProgress + [card])
        if  score > bestScore {
            bestScore = score
            bestIndex = i
        }
    }
    
    if bestIndex == -1 {
        print("ERROR AI unable to pick card from \(hand)")
    }
    
    return bestIndex
}
