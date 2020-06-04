//
//  WaitingScreenViewController.swift
//  Slamwich
//
//  Created by Noah McLean on 4/24/20.
//  Copyright © 2020 Noah McLean. All rights reserved.
//

import UIKit

class WaitingScreenViewController: UIViewController {

    @IBOutlet weak var status: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        while true {
            print("HI")
            status.text = "Searching"
            sleep(4)
            if let _ = GameManager.global.gameID {
                let vc = storyboard!.instantiateViewController(withIdentifier: "Game")
                present(vc, animated: true, completion: nil)
                break
            }
            status.text = "No Response"
            sleep(1)
        }
    }
    

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Cancel" {
            
        }
    }

}
