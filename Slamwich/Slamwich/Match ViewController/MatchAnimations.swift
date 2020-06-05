//
//  MatchAnimations.swift
//  Slamwich
//
//  Created by Noah McLean on 6/4/20.
//  Copyright © 2020 Noah McLean. All rights reserved.
//

import Foundation
import UIKit

// MARK: - Animations
extension MatchViewController {
    
    // Add a new card view & move it to the hand
    func createAndMoveCard(forMe me: Bool, card: Card) {
        // Create the card view
        let newCard = CardView(card: card, at: CGPoint(x: view.center.x, y: 500))
        
        newCard.scaleCard(scale: 0.5, isGrabbed: false)
        
        if !me {
            return
        }
        
        // Make card moveable
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        newCard.isUserInteractionEnabled = true
        newCard.addGestureRecognizer(pan)
                
        // Add view to the board
        self.handContainer.addSubview(newCard)
        
        
        // Animate move
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
            newCard.scaleCard(scale: 1, isGrabbed: false)
            
            newCard.center = CGPoint(x: self.handContainer.center.x, y: self.handContainer.center.y)
    
        }, completion: {
            finished in
            self.rebalanceHand()
        })
    }
    
    // Funky little function that makes a nice fan card effect for the hand
    func rebalanceHand() {
        UIView.animate(withDuration: 0.7, animations: {
            let total = Double(self.handContainer.subviews.count)
            for (i,cardView) in self.handContainer.subviews.enumerated() {
                let ratio: Double = Double(i)/(total)

                // Give slight rotation for fan
                let rotate = (CGFloat(i) - CGFloat(total) * 0.5) * (CGFloat.pi * 0.025)
                cardView.transform = CGAffineTransform(rotationAngle: CGFloat(rotate))
                
                // Pull the cards closer to the center
                let xpt = self.handContainer.bounds.width * CGFloat(ratio) + 25
                let offset = (xpt - (self.handContainer.bounds.width/2.0)) * 0.3
                
                cardView.center = CGPoint(x: xpt - offset, y: self.handContainer.bounds.height/2.0 + (abs(rotate) * 20.0))
                
                
                
            }
        })
    }
    
    // Someone won, who was it and animate the end!
    func declareWinner() {
        if myScore > theirScore {
            turnLabel.text = "YOU WIN!"
            turnLabel.textColor = UIColor(displayP3Red: 0.2, green: 0.6, blue: 0.4, alpha: 1)
        }
        else if myScore == theirScore {
            turnLabel.text = "It's a tie!"
            turnLabel.textColor = UIColor(displayP3Red: 0.7, green: 0.42, blue: 0, alpha: 1)

        }
        else {
            turnLabel.text = "You Lose..."
            turnLabel.textColor = .red
        }
        
        flashTurnLabel()
        endingAnimation(didIWin: myScore > theirScore)
    }
    
    // Display a floating message of a given type (inflection)
    func displayMessage(_ message: String, inflection inf: String) {
        // Instantiate the label
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 20))
        label.text = message
        label.font = .boldSystemFont(ofSize: 16)
        
        // Make label stylized
        if inf == "combo" {
            label.textColor = UIColor.yellow
        }
        else if inf == "bonus" {
            label.textColor = UIColor(displayP3Red: 0, green: 0.4, blue: 0, alpha: 1)
        }
        else if inf == "warning" {
            label.textColor = UIColor(displayP3Red: 0.6, green: 0, blue: 0, alpha: 1)
        }
        else { // This is here for if we forget to add the new inflection in this list
            print("ERROR: unknown displayMessage inflection: \(inf)")
            return
        }
        
        // Add & animate the label
        label.center = sandwichSlot.center
        view.addSubview(label)
        
        UIView.animate(withDuration: 2.5, animations: {
            let newCenter = CGPoint(x: label.center.x, y: 25)
            label.center = newCenter
            label.alpha = 0
        }, completion: {
            _ in
            label.removeFromSuperview()
        })
    }
    
    // Fancy fireworks if we win, either way move out the hand and phase in the button to move on
    func endingAnimation(didIWin me: Bool) {
        if me {
            
            self.emitter.birthRate = 50
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.emitter.birthRate = 0
            }
        }
        
        // Move the cards out of view
       UIView.animate(withDuration: 3, animations: {
           for v in self.handContainer.subviews {
               v.center = CGPoint(x: v.center.x, y: v.center.y + 350)
               
           }
       }, completion: {
           _ in
           
           // Delete the remaining hand views
           for v in self.handContainer.subviews {
               v.removeFromSuperview()
           }
           
           // Phase in transition button
           UIView.animate(withDuration: 1.5, animations: {
               self.endScreenButton.alpha = 1
               self.endScreenButton.isUserInteractionEnabled = true
           })
       })
    }
    
    // Provide a little oomph emphasis for the messages
    func flashTurnLabel() {
        UIView.animate(withDuration: 0.75, animations: {
            self.turnLabel.alpha = 0
            self.turnLabel.alpha = 1
        })
    }
}
