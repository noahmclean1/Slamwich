//
//  MatchViewController.swift
//  Slamwich
//
//  Created by Noah McLean on 4/25/20.
//  Copyright © 2020 Noah McLean. All rights reserved.
//

import UIKit
import SpriteKit

class MatchViewController: UIViewController {

    /*
    MatchViewController
    ------------
    The main brain of the whole app, where all of the gameplay occurs.
     This VC was so huge that I split it into several extensions to make it more readable and manageable. This section is for lifecycle & user interaction functions (as well as IBOutlets & non-method attributes. 
    */
    
    @IBOutlet weak var sandwichSlot: UIView!
    @IBOutlet weak var deckImage: UIImageView!
    @IBOutlet weak var handContainer: UIView!
    @IBOutlet weak var labelTheirScore: UILabel!
    @IBOutlet weak var labelYourScore: UILabel!
    @IBOutlet weak var turnLabel: UILabel!
    @IBOutlet weak var currentValueLabel: UILabel!
    @IBOutlet weak var appearingView: UIView!
    @IBOutlet weak var changePointsLabel: UILabel!
    @IBOutlet weak var changeCombosLabel: UILabel!
    @IBOutlet weak var endScreenButton: UIButton!
    
    var myTurn: Bool!
    var deck = [Card]() {
        didSet {
            if deck.count < 5 {
                displayMessage("\(deck.count) cards remaining", inflection: "warning")
            }
        }
    }
    var opponentDeck = [Card]() {
        didSet {
            if opponentDeck.count < 5 {
                displayMessage("\(opponentDeck.count) cards in other deck", inflection: "warning")
            }
        }
    }
    let winningPoints = 100.0
    var emitter: CAEmitterLayer!
    
    var myHand = [Card]()
    var theirHand = [Card]()
    var sandwich = [Card]()
    var myScore = 0.0 {
        didSet {
            if myScore > winningPoints {
                declareWinner()
            }
        }
    }
    var theirScore = 0.0 {
        didSet {
            if theirScore > winningPoints {
                declareWinner()
            }
        }
    }
    var expanded = false
    var movePrediction: Card? {
        didSet {
            if let card = movePrediction {
                let diffCombos = newCombosFrom(sandwich, newCard: card, activeCombos)
                changeCombosLabel.text = combosToString(diffCombos)
                let newScore = scoreSandwich(sandwich + [card]).0 - currentScore
                changePointsLabel.text = "\(newScore < 0 ? "" : "+")\(newScore)"
                
                UIView.animate(withDuration: 0.5, animations: {
                    self.appearingView.alpha = 1
                })
                
                
            }
            else {
                UIView.animate(withDuration: 0.25, animations: {
                    self.appearingView.alpha = 0
                })
            }
        }
    }
    var activeCombos = [Combo]()
    var currentScore = 0.0 {
        didSet {
            currentValueLabel.text = String(currentScore)
        }
    }
    var longestSandwich = [Card]()
    
    // MARK: - Lifecycle Functions
    override func viewDidLoad() {
        super.viewDidLoad()

        overrideUserInterfaceStyle = .light
        
        // Initialize eating animation on completing a sandwich
        var imgList = [UIImage]()
        for i in 1...5 {
            let img = UIImage(named: "Sandwich\(i)")!
            imgList.append(img)
        }
        deckImage.animationImages = imgList
        deckImage.animationDuration = 1
        deckImage.animationRepeatCount = 1

        // Attach the "peek" function to the central slot
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapToRevealSandwich(_:)))
        sandwichSlot.addGestureRecognizer(tap)
        
        // Style the hovering view
        appearingView.layer.cornerRadius = 15
        appearingView.alpha = 0
        
        // Style end game button
        endScreenButton.layer.cornerRadius = 15
        
        // Set up emitter layer for victories
        let emit = CAEmitterLayer()
        emit.position = CGPoint(x: sandwichSlot.center.x, y: 0.0)
        
        let cell = CAEmitterCell()
        cell.name = "spark"
        cell.birthRate = 50
        cell.lifetime = 14
        cell.velocity = 200
        cell.yAcceleration = 50.0
        cell.scale = 0.1
        cell.scaleRange = 0.2
        cell.alphaSpeed = -0.1
        cell.color = CGColor(srgbRed: 0.5, green: 0.5, blue: 0.5, alpha: 1)
        cell.redRange = 0.8
        cell.blueRange = 0.8
        cell.greenRange = 0.8
        
        cell.emissionRange = CGFloat.pi * 2.0
        cell.contents = UIImage(named: "spark")!.cgImage
        
        emit.emitterCells = [cell]
        emit.birthRate = 0
            
        view.layer.addSublayer(emit)
        
        emitter = emit
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // If the game isn't started, begin!
        if !gameInProgress {
            gameInProgress = true
            startGame()
            
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ExitFromGame" {
            // Quit game on exit
            gameInProgress = false
        }
        else if segue.identifier == "EndScreen" {
            if let vc = segue.destination as? EndScreenViewController {
                // If it's a tie, pass nil to the VC
                if myScore != theirScore {
                    vc.winner = myScore > theirScore
                }
                // Pass best sandwich & scores
                vc.bestSandwich = longestSandwich
                vc.myScore = myScore
                vc.theirScore = theirScore
            }
        }
    }
    
  
    
    // MARK: - User Interaction
    
    // Vital panning function for each card in your hand
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        guard let gView = gesture.view else {
            return
        }
        guard let gestureView = gView as? CardView else {
            return
        }
        
        // Placement details if you drop the card
        if (gesture.state == .ended) {
            // Overlaps with the slot
            if checkOverlap(cardView: gestureView) {
                
                // Fade out predictor view (on top)
                movePrediction = nil
                
                // Is the play valid? Then play it!
                if validPlay(card: gestureView.card, sandwich: sandwich) && !expanded{
                                        
                    gestureView.scaleCard(scale: 1.25, isGrabbed: true)
                    gestureView.removeFromSuperview()
                    sandwichSlot.addSubview(gestureView)
                    gestureView.center = sandwichSlot.convert(sandwichSlot.center, from: view)
                    
                    // Log the card in the sandwich
                    let points = playCard(gestureView.card)
                    if points != 0.0 {
                        myScore += points
                        labelYourScore.text = String(myScore)
                        if myScore >= winningPoints {
                            return
                        }
                    }
                    
                    // Find and remove the card played from my hand
                    for (i,card) in myHand.enumerated() {
                        if card.name == gestureView.card.name {
                            myHand.remove(at: i)
                            break
                        }
                    }
                    
                    // Fill in card gap
                    rebalanceHand()
                    
                    // End my turn
                    startTurn(forMe: false)
                    return
                }
                
            }
            
            // If not overlapping or invalid, put it back
            gestureView.scaleCard(scale: 1.0, isGrabbed: true)
            rebalanceHand()
            return
        }
        else if (gesture.state == .began) {
            // Provide a nice pick-up effect for cards
            gestureView.scaleCard(scale: 1.1, isGrabbed: true)
            return
        }
                
        // Move the view properly
        gestureView.center = CGPoint(
        x: gestureView.center.x + translation.x,
        y: gestureView.center.y + translation.y
        )

        gesture.setTranslation(.zero, in: view)
        
        // Check for hovering intersection & display info
        if checkOverlap(cardView: gestureView) {
            movePrediction = gestureView.card
        }
        else {
            movePrediction = nil
        }
        
    }
    
    // Handy function for checking if the card can be placed
    func checkOverlap(cardView: UIView) -> Bool {
        // We define the hitbox as a hidden inside view
        let actualFrame = cardView.superview!.convert(sandwichSlot.subviews[0].bounds, from: sandwichSlot.subviews[0])
        if cardView.frame.intersects(actualFrame) {
            return true
        }
        return false
    }
    
    // Peek function that shows what's in the pile
    @objc func tapToRevealSandwich(_ gesture: UITapGestureRecognizer) {
        // Tap on expanded sandwich -> flatten back to normal & allow playing
        if expanded {
            for view in sandwichSlot.subviews {
                UIView.animate(withDuration: 1, animations: {
                    
                    view.center = self.sandwichSlot.convert(self.sandwichSlot.center, from: self.view)
                })
            }
            turnLabel.text = "Your Turn"
            expanded = false
        }
        // Tap on a normal sandwich -> peek at cards
        else {
            if sandwich.count == 0 {
                return
            }
            
            let num = sandwichSlot.subviews.count

            for (i,view) in sandwichSlot.subviews.enumerated() {
                UIView.animate(withDuration: 1, animations: {
                    // Bring the whole stack upwards so there's more room below
                    let minimum = self.sandwichSlot.convert(self.sandwichSlot.bounds, from: self.view).minY  + (view.bounds.height / 2.0)
                    let offset = max((CGFloat(i - num) * 10.0) - 85, minimum)
                    // Cap the bottom of the stack so it doesn't clip
                    let maximum = self.sandwichSlot.convert(self.sandwichSlot.bounds, from: self.view).maxY - (view.bounds.height / 2.0)
                    // Move each view in the stack for visibility
                    view.center.y += min((CGFloat(i) * 10.0) + offset, maximum)
                })
            }
            turnLabel.text = "Peeking..."
            expanded = true
        }
        flashTurnLabel()
    }
}

