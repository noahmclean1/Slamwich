//
//  ViewController.swift
//  Slamwich
//
//  Created by Noah McLean on 3/23/20.
//  Copyright © 2020 Noah McLean. All rights reserved.
//

import UIKit

class MainPlayerViewController: UIViewController {

    @IBOutlet var cardSlots: [UIView]!
    @IBOutlet weak var cardContainer: CardView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let tap = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        cardContainer.addGestureRecognizer(tap)
    }

    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        
        guard let gView = gesture.view else {
            return
        }
        
        guard let gestureView = gView as? CardView else {
            return
        }

        if (gesture.state == .ended) {
            let num = checkOverlap(cardView: gestureView)
            if num == -1 {
                gestureView.scaleCard(scale: 1.0)
            }
            else {
                gestureView.scaleCard(scale: 0.75)
            }
        }
        else if (gesture.state == .began) {
            gestureView.scaleCard(scale: 1.1)
        }
                
        gestureView.center = CGPoint(
        x: gestureView.center.x + translation.x,
        y: gestureView.center.y + translation.y
        )

        gesture.setTranslation(.zero, in: view)
        
        
        }
    
    func checkOverlap(cardView: UIView) -> Int {
        for slot in cardSlots {
            if cardView.frame.intersects(slot.frame) {
                return slot.tag
            }
        }
        return -1
    }

        
}

