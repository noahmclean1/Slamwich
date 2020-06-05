//
//  InstructionsViewController.swift
//  Slamwich
//
//  Created by Noah McLean on 6/2/20.
//  Copyright © 2020 Noah McLean. All rights reserved.
//

import UIKit

class InstructionsViewController: UIViewController {

    /*
    InstructionsViewController
    ------------
    Shows how to play the game
    */
    
    @IBOutlet weak var mainInstructions: UITextView!
    @IBOutlet weak var comboTable: UITableView!
    
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var comboName: UILabel!
    @IBOutlet weak var ingredientsList: UILabel!
    @IBOutlet weak var typesList: UILabel!
    
    
    var realCombos: [Combo]!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        overrideUserInterfaceStyle = .light
        
        // Add in instructions in a properly formatted manner
        mainInstructions.text = """
                                Slamwich is a game about making (and eating) sandwiches.\n
                                You will be dealt a hand of cards, each of which is an ingredient. Play a card by dragging it on top of the sandwich pile. \n
                                Whoever plays a piece of bread on top of a sandwich completes that sandwich and earns all of its points. When either player reaches 100 points or runs out of cards to draw, a winner is declared!\n
                                Combos award bonus points to a sandwich with certain types of cards in it. Score more points by making bigger sandwiches and forming combos!\n
                                How tall can you make your sandwich before your opponent steals it? Good luck!
                                """
        
        // Grab the combo list and display
        if combos == nil {
            readInCombos()
        }
        
        realCombos = combos!
        
        comboTable.delegate = self
        comboTable.dataSource = self
        comboTable.reloadData()
    }
    
    @IBAction func back(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    // Handy function to show combo info
    func describeCombo(_ combo: Combo) {
        comboName.text = combo.name
        valueLabel.text = "x\(combo.multiplier)"
        ingredientsList.text = listToString(combo.cards)
        typesList.text = listToString(combo.types)
    }
    
    // Helper to display listed info
    func listToString(_ list: [String]) -> String {
        let cnt = list.count
        var combined = ""
        for (i,item) in list.enumerated() {
            combined += item
            if i != cnt-1 {
                combined += "\n"
            }
        }
        return combined
    }
}

// MARK: - TableView Extension
extension InstructionsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return realCombos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "combo") as! ComboTableViewCell
        
        let combo = realCombos[indexPath.row]
        cell.comboTitle.text = combo.name
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let combo = realCombos[indexPath.row]
        describeCombo(combo)
        tableView.cellForRow(at: indexPath)?.isSelected = false
    }
}
