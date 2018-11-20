//
//  StudentCollectionViewCell.swift
//  faceIT
//
//  Created by Arnav Gupta on 11/4/18.
//  Copyright © 2018 NovaTec GmbH. All rights reserved.
//

import UIKit

class StudentCollectionViewCell: UITableViewCell {
    @IBOutlet weak var picture: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var andrewId: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        picture.layer.cornerRadius = 15.0;
        picture.layer.masksToBounds = true;
    }

}
