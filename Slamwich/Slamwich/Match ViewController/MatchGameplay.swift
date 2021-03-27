//
//  MatchGameplay.swift
//  Slamwich
//
//  Created by Noah McLean on 6/4/20.
//  Copyright © 2020 Noah McLean. All rights reserved.
//

import Foundation
import UIKit

// MARK: - Game Interaction Functions
extension MatchViewController {
    
    // Begin the whole process!
    func startGame() {
        // Create and shuffle both decks
        deck = createDeck()
        deck.shuffle()
        
        opponentDeck = createDeck()
        opponentDeck.shuffle()
        
        // Save combos into memory
        readInCombos()
        
        // Start with one sandwich slot
        sandwich = [Card]()
        
        // Both players draw hands
        let handSize = 5
        
        // We can force these card draws because we know they're from full decks
        for _ in 1...handSize {
            let myCard = drawCard(fromMe: true)!
            addCardTo(myHand: true, card: myCard)
            let theirCard = drawCard(fromMe: false)!
            addCardTo(myHand: false, card: theirCard)
        }
        
        // Begin the sandwich with a piece of bread
        let bread = generateBread()
        sandwich.append(bread)
        (currentScore, activeCombos) = scoreSandwich(sandwich)
        
        // Animate bread appearance
        let newcard = CardView(card: bread, at: sandwichSlot.center)
        sandwichSlot.addSubview(newcard)
        newcard.scaleCard(scale: 1.25, isGrabbed: true)
        newcard.center = sandwichSlot.convert(sandwichSlot.center, from: self.view)
        displayMessage("Free Bread!", inflection: "bonus")
        
        // Start playing
        startTurn(forMe: myTurn)
    }
    
    // Draw a card for the player (nil -> end the game)
    func drawCard(fromMe me: Bool) -> Card? {
        if me {
            if deck.count == 0 {
                return nil
            }
            let card = deck[0]
            deck.removeFirst()
            return card
        }
        else {
            if opponentDeck.count == 0 {
                return nil
            }
            let card = opponentDeck[0]
            opponentDeck.removeFirst()
            return card
        }
    }
    
    // Animate the new card's addition
    func addCardTo(myHand me: Bool, card: Card) {
        if me {
            myHand.append(card)
            
        }
        else {
            theirHand.append(card)
        }
        createAndMoveCard(forMe: me, card: card)
    }
    
    // MARK: - Turns
      func startTurn(forMe me: Bool) {
          // Start turn by drawing a card
          let card = drawCard(fromMe: me)
          if card == nil {
              declareWinner()
              return
          }
          addCardTo(myHand: me, card: card!)
          
          
                  
          // If there are no started sandwiches, and no one has bread give a helping hand
          let currentHand = me ? myHand : theirHand
          if sandwich.isEmpty && isGameStuck(hand: currentHand) {
              // Actually add the bread
              let bread = generateBread()
              sandwich.append(bread)
              (currentScore, activeCombos) = scoreSandwich(sandwich)
              
              // Animate bread appearance
              let newcard = CardView(card: bread, at: sandwichSlot.center)
              sandwichSlot.addSubview(newcard)
              newcard.scaleCard(scale: 1.25, isGrabbed: true)
              newcard.center = sandwichSlot.convert(sandwichSlot.center, from: self.view)
              displayMessage("Free Bread!", inflection: "bonus")
          }
          
        // Whoever's turn, visually show the change
          if me {
              turnLabel.text = "Your Turn"
              turnLabel.textColor =  UIColor(displayP3Red: 0.0, green: 0.5, blue: 0.169, alpha: 1)
              flashTurnLabel()
              
              for (i,view) in handContainer.subviews.enumerated() {
                  view.isUserInteractionEnabled = true
                
                // Phase in playable cards
                  UIView.animate(withDuration: 0.25, animations: {
                      if self.sandwich.count != 0 || self.myHand[i].type == "bread" {
                          view.alpha = 1.0
                      }
                  })
              }
          }
          // TODO: add in check for online play when applicable
          else {
              turnLabel.text = "Waiting for Opponent..."
              turnLabel.textColor = .orange
              flashTurnLabel()
              
              for view in handContainer.subviews {
                  view.isUserInteractionEnabled = false
                
                // Phase out all cards
                  UIView.animate(withDuration: 0.25, animations: {
                      view.alpha = 0.5
                  })
              }
              
              // Perform the AI's turn logic
              let play = pickACardAI(hand: theirHand, sandwichInProgress: sandwich)
              let theirCard = theirHand[play]
              

              let playedCard = CardView(card: theirCard, at: CGPoint(x: 0, y: -500))
              
              // Animate play
              UIView.animate(withDuration: 1.5, animations: {
                  playedCard.scaleCard(scale: 1.25, isGrabbed: true)
                  self.sandwichSlot.addSubview(playedCard)
                  playedCard.center = self.sandwichSlot.convert(self.sandwichSlot.center, from: self.view)
              }, completion: {
                  _ in
                  let points = self.playCard(theirCard)
                  self.theirHand.remove(at: play)
                  if points != 0.0 {
                      self.theirScore += points
                      self.labelTheirScore.text = String(self.theirScore)
                      if self.theirScore >= self.WINNING_POINTS {
                          return
                      }
                  }
                  self.startTurn(forMe: true)
              })
              
              
              
              
          }
      }
      
      func playCard(_ card: Card) -> Double {
          sandwich.append(card)
          
          // Completing a sandwich
          if card.type == "bread" && sandwich.count > 1 {
              let (score, curCombos) = scoreSandwich(sandwich)
              
              // Keep track of the largest sandwich
              if sandwich.count > longestSandwich.count {
                  longestSandwich = sandwich
              }
              
              sandwich = []
              
              // Show a little ping for new combos
              for c in curCombos {
                  if !activeCombos.contains(c) {
                      displayMessage("\(c.name): x\(c.multiplier)", inflection: "combo")
                  }
              }
              
              // Reset card visual
              for view in sandwichSlot.subviews {
                  if view.tag != 1 {
                      view.removeFromSuperview()
                  }
              }
              
              // Play the eating animation
              deckImage.startAnimating()
              
              activeCombos = []
              currentScore = 0.0
              return score
          }
          
          var curCombos: [Combo]
          (currentScore, curCombos) = scoreSandwich(sandwich)
          
          // Show a nice notification for new combos
          for c in curCombos {
              if !activeCombos.contains(c) {
                  displayMessage("\(c.name): x\(c.multiplier)", inflection: "combo")
              }
          }
          
          activeCombos = curCombos
          
          return 0.0
      }
}
