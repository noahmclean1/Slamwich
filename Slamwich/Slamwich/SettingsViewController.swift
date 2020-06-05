//
//  SettingsViewController.swift
//  Slamwich
//
//  Created by Noah McLean on 6/2/20.
//  Copyright © 2020 Noah McLean. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    /*
    SettingsViewController
    ------------
    For now contains relatively little, but may be improved later
    */
    
    override func viewDidLoad() {
        super.viewDidLoad()

        overrideUserInterfaceStyle = .light
    }
    
    @IBAction func back(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

}
