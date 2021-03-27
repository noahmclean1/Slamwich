//
//  CardView.swift
//  Slamwich
//
//  Created by Noah McLean on 4/2/20.
//  Copyright © 2020 Noah McLean. All rights reserved.
//

import UIKit

@IBDesignable
class CardView: UIView {

    /*
     CardView
     ------------
     A visual view-form of a given card to use & display
     */
    
    @IBOutlet weak var cardTitle: UILabel!
    @IBOutlet weak var cardType: UILabel!
    @IBOutlet weak var cardDescription: UILabel!
    @IBOutlet weak var cardImage: UIImageView!
    @IBOutlet weak var valueContainer: UIView!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var innerContainer: UIView!
    
    let card: Card!
    
    var currentScale = 1.0

    init(card: Card, at: CGPoint) {
        let frame = CGRect(x: at.x, y: at.y, width: 150, height: 250)
        self.card = card
        super.init(frame: frame)
        setupView(withCard: card)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.card = try! Card(fromDictionary: NSDictionary(), withType: "")
        super.init(coder: aDecoder)
        //setupView()
    }
    
    // MARK: - General Setup
    
    // Performs all the necessary work to make a card view have the proper info and appear
    private func setupView(withCard cardStruct: Card) {
        // Attach view to nib properly
        let card = Bundle.main.loadNibNamed("CardView", owner: self, options: nil)![0] as! UIView
        
        // Set up backing card details
        let layer = card.layer

        // Configure visual details
        layer.cornerRadius = 10
        innerContainer.layer.cornerRadius = 10
        
        // The "card" is essentially an inner view but we can treat it all as one
        self.addSubview(card)
                
        // Set up card text
        cardTitle.text = cardStruct.name
        cardType.text = cardStruct.type
        cardDescription.text = cardStruct.description
        valueLabel.text = String(cardStruct.value)
        valueContainer.layer.cornerRadius = 5
        
        // Set up card image
        cardImage.image = CardView.getCardImage(card: cardStruct)
        card.backgroundColor = CardView.pickColorForType(type: self.card.type)
    }
    
    // MARK: - Helper Functions
    // Generalized function to scale a card view
    // Used on pick up, placement, etc
    func scaleCard(scale: Double, isGrabbed: Bool) {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
            var transform = self.transform
            transform = transform.scaledBy(x: CGFloat(scale), y: CGFloat(scale))
            self.transform = transform
            self.currentScale = scale
            
            // If the player picks up the card, we need to signal a slight change so it doesn't clip weirdly
            if !isGrabbed {
                self.layer.position = CGPoint(x: self.frame.minX, y: self.frame.minY)
            }

        }, completion: nil)
    }

    // Useful function to easily get the proper image when loading a card
    static func getCardImage(card: Card) -> UIImage {
        // Check if there's a specific image
        if let img = UIImage(named: card.name) {
            return img
        }
        
        // Check if the type has an image (it should)
        if let img = UIImage(named: card.type) {
            return img
        }
        
        // Default an empty image
        return UIImage()
    }
    
    // Similar to above, but each type has a specific color for various uses
    static func pickColorForType(type: String) -> UIColor {
        var color: UIColor
        switch type {
        case "bread":
            color = UIColor(displayP3Red: 0.5, green: 0.17, blue: 0.1, alpha: 1)
        case "cheese":
            color = UIColor(displayP3Red: 1.0, green: 0.76, blue: 0.0, alpha: 1)
        case "meat":
            color = UIColor(displayP3Red: 1.0, green: 0.5, blue: 0.4, alpha: 1)
        case "veggie":
            color = UIColor(displayP3Red: 0.19, green: 0.5, blue: 0.1, alpha: 1)
        case "condiment":
            color = UIColor(displayP3Red: 0.93, green: 0.93, blue: 0.8, alpha: 1)
        case "fruit":
            color = UIColor(displayP3Red: 0.78, green: 0.53, blue: 0.85, alpha: 1)
        default:
            return UIColor.darkGray
        }
        return color
    }
}
