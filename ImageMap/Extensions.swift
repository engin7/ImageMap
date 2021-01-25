//
//  Extensions.swift
//  ImageMap
//
//  Created by Engin KUK on 24.01.2021.
//

import UIKit.UIView
 

extension CGPoint {
 
   
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow(x - point.x, 2) + pow(y - point.y, 2))
    }
  
    
    func getSubViewTouched(imageView: UIImageView) -> UIView? {
        
        let leftTopTolerance = CGPoint(x: self.x-10,y: self.y-10)
        let leftBottomTolerance = CGPoint(x: self.x-10,y: self.y+10)
        let rightBottomTolerance = CGPoint(x: self.x+10,y: self.y+10)
        let rightTopTolerance = CGPoint(x: self.x+10,y: self.y-10)

        let filteredSubviews = imageView.subviews.filter { subView -> Bool in
            return subView.frame.contains(self) || subView.frame.contains(leftTopTolerance) || subView.frame.contains(leftBottomTolerance) || subView.frame.contains(rightBottomTolerance) || subView.frame.contains(rightTopTolerance)
          }
        guard let subviewTapped = filteredSubviews.first else {
            return nil
        }
        return subviewTapped
    }
    
}

extension Array where Element == CGPoint {
    
    func centroid() -> CGPoint? {
        
        if isEmpty { return nil }
        
        let edges = self.count
        var totX: [CGFloat] = []
        self.forEach{totX.append($0.x)}
        let avgX = totX.reduce(0,+) / CGFloat(edges)
        var totY: [CGFloat] = []
        self.forEach{totY.append($0.y)}
        let avgY = totY.reduce(0,+) / CGFloat(edges)
        
        return CGPoint(x: avgX, y: avgY)
        
    }
    
}
