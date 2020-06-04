//
//  ViewController.swift
//  Slamwich
//
//  Created by Noah McLean on 3/23/20.
//  Copyright © 2020 Noah McLean. All rights reserved.
//

import UIKit
import FirebaseDatabase

class MainPlayerViewController: UIViewController {

    @IBOutlet weak var breadtop: UIImageView!
    @IBOutlet weak var logo: UIImageView!
    @IBOutlet weak var breadbottom: UIImageView!
    @IBOutlet weak var versionLabel: UILabel!
    
    let logoOffset: CGFloat = 300.0
    var logoInPlace = false
    var ref: DatabaseReference!
    var isQueued = false {
        didSet {
            // TODO
            print(isQueued)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Spawn the views upwards
        breadtop.center.y -= logoOffset
        breadbottom.center.y -= logoOffset
        logo.center.y -= logoOffset
        
        let version: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        
        versionLabel.text = "patch \(version)"

        
        overrideUserInterfaceStyle = .light
        ref = Database.database().reference()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !logoInPlace {
            // Drop the sandwich pieces down
            dropPiece(piece: breadbottom, completion: {
                _ in
                self.dropPiece(piece: self.logo, completion: {
                    _ in
                    self.dropPiece(piece: self.breadtop, completion: nil)
                })
            })
            
            logoInPlace = true
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Find Match" {
            
        }
        if segue.identifier == "AIMatch" {
            guard let vc = segue.destination as? MatchViewController else {return}
            vc.myTurn = Bool.random()
            
        }
    }
    
    func dropPiece(piece: UIImageView, completion: ((Bool) -> ())?) {
        UIView.animate(withDuration: 0.5, animations: {
            piece.center = CGPoint(x: piece.center.x, y: piece.center.y
                + self.logoOffset)
        }, completion: completion)
    }
    
    @IBAction func lookForMatch(_ sender: Any) {
        GameManager.global.enqueueUser(user: "me!")
    }
    
    @IBAction func sendData(_ sender: Any) {
        let user = "added"
        GameManager.global.enqueueUser(user: user)
    }
    
    @IBAction func grabData(_ sender: Any) {
        ref.child("queuedUsers").observe(.value, with: { (snapshot) in
            guard let val = snapshot.value as? Dictionary<String, Any> else {return}
            print("--- GRAB DATA ---")
            print(val.count)
            print(val)
        })
    }
}

