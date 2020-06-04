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
        
        var imgList = [UIImage]()
        for i in 1...5 {
            let img = UIImage(named: "Sandwich\(i)")!
            imgList.append(img)
        }
        
        deckImage.animationImages = imgList
        deckImage.animationDuration = 1
        deckImage.animationRepeatCount = 1

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapToRevealSandwich(_:)))
        sandwichSlot.addGestureRecognizer(tap)
        
        appearingView.layer.cornerRadius = 15
        appearingView.alpha = 0
        
        endScreenButton.layer.cornerRadius = 15
        
        // Set up emitter layer
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
        
        
        if !gameInProgress {
            gameInProgress = true
            startGame()
            
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ExitFromGame" {
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

    
    // MARK: - Game Interaction Functions
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
        
        
        startTurn(forMe: myTurn)
    }
    
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
        
        if me {
            turnLabel.text = "Your Turn"
            turnLabel.textColor =  UIColor(displayP3Red: 0.0, green: 0.5, blue: 0.169, alpha: 1)
            flashTurnLabel()
            
            for (i,view) in handContainer.subviews.enumerated() {
                view.isUserInteractionEnabled = true
                UIView.animate(withDuration: 0.25, animations: {
                    if self.sandwich.count != 0 || self.myHand[i].type == "bread" {
                        view.alpha = 1.0
                    }
                })
            }
        }
        else {
            turnLabel.text = "Waiting for Opponent..."
            turnLabel.textColor = .orange
            flashTurnLabel()
            
            for view in handContainer.subviews {
                view.isUserInteractionEnabled = false
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
                    if self.theirScore >= self.winningPoints {
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
    
    // MARK: - Animations
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
        //self.view.addSubview(newCard)
        self.handContainer.addSubview(newCard)
        
        
        // Animate move
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
            newCard.scaleCard(scale: 1, isGrabbed: false)
            
            //let handOffset = 35.0 * Double(self.myHand.count)
            newCard.center = CGPoint(x: self.handContainer.center.x, y: self.handContainer.center.y)
            
            
        }, completion: {
            finished in
            self.rebalanceHand()
        })
    }
    
    func rebalanceHand() {
        UIView.animate(withDuration: 0.7, animations: {
            let total = Double(self.handContainer.subviews.count)
            for (i,cardView) in self.handContainer.subviews.enumerated() {
                let ratio: Double = Double(i)/(total)

                let rotate = (CGFloat(i) - CGFloat(total) * 0.5) * (CGFloat.pi * 0.025)
                cardView.transform = CGAffineTransform(rotationAngle: CGFloat(rotate))
                
                // Pull the cards closer to the center
                let xpt = self.handContainer.bounds.width * CGFloat(ratio) + 25
                let offset = (xpt - (self.handContainer.bounds.width/2.0)) * 0.3
                
                cardView.center = CGPoint(x: xpt - offset, y: self.handContainer.bounds.height/2.0 + (abs(rotate) * 20.0))
                
                
                
            }
        })
    }
    
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
        else {
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
    
    func flashTurnLabel() {
        UIView.animate(withDuration: 0.75, animations: {
            self.turnLabel.alpha = 0
            self.turnLabel.alpha = 1
        })
    }
    
    // MARK: - User Interaction
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        
        
        guard let gView = gesture.view else {
            return
        }
        
        guard let gestureView = gView as? CardView else {
            return
        }
        
        

        if (gesture.state == .ended) {
            // Overlaps with a slot
            if checkOverlap(cardView: gestureView) {
                
                // Fade out prediction
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
    
    func checkOverlap(cardView: UIView) -> Bool {
        // We define the hitbox as a hidden inside view
        let actualFrame = cardView.superview!.convert(sandwichSlot.subviews[0].bounds, from: sandwichSlot.subviews[0])
        if cardView.frame.intersects(actualFrame) {
            return true
        }
        return false
    }
    
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

