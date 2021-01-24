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
    /// Calculate signed area.
    ///
    /// See https://en.wikipedia.org/wiki/Centroid#Of_a_polygon
    ///
    /// - Returns: The signed area

    func signedArea() -> CGFloat {
        if isEmpty { return .zero }

        var sum: CGFloat = 0
        for (index, point) in enumerated() {
            let nextPoint: CGPoint
            if index < count-1 {
                nextPoint = self[index+1]
            } else {
                nextPoint = self[0]
            }

            sum += point.x * nextPoint.y - nextPoint.x * point.y
        }

        return sum / 2
    }

    /// Calculate centroid
    ///
    /// See https://en.wikipedia.org/wiki/Centroid#Of_a_polygon
    ///
    /// - Note: If the area of the polygon is zero (e.g. the points are collinear), this returns `nil`.
    ///
    /// - Parameter points: Unclosed points of polygon.
    /// - Returns: Centroid point.

    func centroid() -> CGPoint? {
        if isEmpty { return nil }

        let area = signedArea()
        if area == 0 { return nil }

        var sumPoint: CGPoint = .zero

        for (index, point) in enumerated() {
            let nextPoint: CGPoint
            if index < count-1 {
                nextPoint = self[index+1]
            } else {
                nextPoint = self[0]
            }

            let factor = point.x * nextPoint.y - nextPoint.x * point.y
            sumPoint.x += (point.x + nextPoint.x) * factor
            sumPoint.y += (point.y + nextPoint.y) * factor
        }

        return sumPoint / 6 / area
    }

    func mean() -> CGPoint? {
        if isEmpty { return nil }

        return reduce(.zero, +) / CGFloat(count)
    }
}

extension CGPoint {
    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    static func / (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        CGPoint(x: lhs.x / rhs, y: lhs.y / rhs)
    }

    static func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
    }
}
