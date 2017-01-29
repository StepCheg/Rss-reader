//
//  CollectionViewLayout.swift
//  Test Reader
//
//  Created by Stepan Chegrenev on 06.11.16.
//  Copyright © 2016 Stepan Chegrenev. All rights reserved.
//

import UIKit

class CollectionViewLayout: UICollectionViewLayout {

    var heightOfFrame: Double!
    var widthOfFrame: Double!
    var cellCount: Int!
    let spaceBetweenCells: Double = 0

    
    override var collectionViewContentSize: CGSize
        {
        get
        {
            return CGSize(width: Double(self.collectionView!.frame.size.width), height: spaceBetweenCells + (spaceBetweenCells * Double(cellCount)) + (heightOfFrame * Double(cellCount)))
        }
    }
    
    
    override func prepare()
    {
        super.prepare()
        
        heightOfFrame = 100
        widthOfFrame = Double(self.collectionView!.frame.size.width) - (spaceBetweenCells * 2)
        
        cellCount = self.collectionView!.numberOfItems(inSection: 0)
    }
    
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]?
    {
        var attributes = [UICollectionViewLayoutAttributes]()
        
        for item in 0..<cellCount
        {
            let indexPath = IndexPath(item: item, section: 0)
            attributes.append(self.layoutAttributesForItem(at: indexPath)!)
        }
        
        return attributes
    }
    
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes?
    {
        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        
        attributes.size = CGSize(width: widthOfFrame, height: heightOfFrame)
        
        var pointX: Double
        var pointY: Double
        
        pointX = (Double(self.collectionView!.frame.size.width) - widthOfFrame) / 2
        pointY = spaceBetweenCells + (spaceBetweenCells * Double(indexPath.row)) + (heightOfFrame * Double(indexPath.row))
        
        attributes.frame = CGRect(x: pointX, y: pointY, width: widthOfFrame, height: heightOfFrame)

        return attributes;
    }
    
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool
    {
        return false
    }
}
