//
//  CollectionViewCell.swift
//  Test Reader
//
//  Created by Stepan Chegrenev on 09.11.16.
//  Copyright © 2016 Stepan Chegrenev. All rights reserved.
//

import UIKit

class CollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var sourceLabel: UILabel!
    @IBOutlet weak var newsImage: UIImageView!
    
    
    func changeDate(pubDate date: NSDate) -> String
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        let convertDate = dateFormatter.string(from: date as Date)
        return convertDate
    }
}
