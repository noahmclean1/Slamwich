//
//  EndScreenViewController.swift
//  Slamwich
//
//  Created by Noah McLean on 6/2/20.
//  Copyright © 2020 Noah McLean. All rights reserved.
//

import UIKit

class EndScreenViewController: UIViewController {

    /*
    EndScreenViewController
    ------------
    A nice recap screen for after the game
    */
    
    @IBOutlet weak var mainTitle: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var sandwichTable: UITableView!
    @IBOutlet weak var otherScoreLabel: UILabel!
    
    var bestSandwich = [Card]()
    var myScore = 0.0
    var theirScore = 0.0
    var winner: Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        overrideUserInterfaceStyle = .light
        
        // Visually update the screen with the proper info
        if let w = winner {
            if w {
                mainTitle.text = "You Win!"
            }
            else {
                mainTitle.text = "You Lose..."
            }
        }
        else {
            mainTitle.text = "It's a Tie!"
        }
        
        scoreLabel.text = String(myScore)
        otherScoreLabel.text = String(theirScore)

        // Show the biggest sandwich played
        sandwichTable.delegate = self
        sandwichTable.dataSource = self
        sandwichTable.reloadData()
    }
    

}

// MARK: - TableView Extension
extension EndScreenViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bestSandwich.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let card = bestSandwich[indexPath.row]
        if let cell = tableView.dequeueReusableCell(withIdentifier: "card") as? CardTableViewCell {
            let col = CardView.pickColorForType(type: card.type)
            cell.colorView.backgroundColor = col
            cell.cardName.text = card.name
            cell.cardImg.image = CardView.getCardImage(card: card)
            
            return cell
        }
        
        return UITableViewCell()
    }
    
    
}
