//
//  ViewController.swift
//  Slamwich
//
//  Created by Noah McLean on 3/23/20.
//  Copyright © 2020 Noah McLean. All rights reserved.
//

import UIKit

class MainPlayerViewController: UIViewController {

    @IBOutlet weak var cardContainer: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let layer = cardContainer.layer
        layer.borderColor = CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1)
        layer.borderWidth = 1
        layer.cornerRadius = 10
    }


}

