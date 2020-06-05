//
//  SplashViewController.swift
//  Slamwich
//
//  Created by Noah McLean on 6/3/20.
//  Copyright © 2020 Noah McLean. All rights reserved.
//

import UIKit

class SplashViewController: UIViewController {

    /*
    SplashViewController
    ------------
    Really just a cute splash screen
    */
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Make sure the screen stays up for a bit, then move to menu
        sleep(2)
        
        performSegue(withIdentifier: "showMainMenu", sender: self)
    }

}
