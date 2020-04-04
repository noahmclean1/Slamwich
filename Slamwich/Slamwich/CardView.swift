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

    @IBOutlet var view: UIView!
    var currentScale = 1.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    // General setup
    private func setupView() {
        // Attach view to nib properly
        let bundle = Bundle(for: CardView.self)
        bundle.loadNibNamed("CardView", owner: self, options: nil)
        
        view.frame = bounds
        view.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth,
                                 UIView.AutoresizingMask.flexibleHeight]
        addSubview(view)
        
        // Set up minute card details
        let layer = view.layer
        layer.backgroundColor = CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0)
        layer.borderColor = CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1)
        layer.borderWidth = 1
        layer.cornerRadius = 10
        view.backgroundColor = .brown
    }
    
    func scaleCard(scale: Double) {
        
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {

            //print(self.frame)

            //let offset: CGFloat = 25
            /*
            let offsetX = 2 * (offset / self.frame.width)
            let offsetY = 2 * (offset * (self.frame.height / self.frame.width) / self.frame.height)
 */
            var transform = CGAffineTransform.identity
            transform = transform.scaledBy(x: CGFloat(scale), y: CGFloat(scale))
            self.transform = transform
            self.currentScale = scale
            //self.layer.position = CGPoint(x: offset, y: offset)

        }, completion: nil)
    }

}
