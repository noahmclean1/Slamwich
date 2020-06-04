//
//  CardTableViewCell.swift
//  Slamwich
//
//  Created by Noah McLean on 6/3/20.
//  Copyright © 2020 Noah McLean. All rights reserved.
//

import UIKit

class CardTableViewCell: UITableViewCell {
    
    @IBOutlet weak var colorView: UIView!
    @IBOutlet weak var cardName: UILabel!
    @IBOutlet weak var cardImg: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
