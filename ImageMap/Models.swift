//
//  Models.swift
//  ImageMap
//
//  Created by Engin KUK on 27.01.2021.
//

import UIKit
 
enum EnumLayoutMapActivity: Int {
    case VIEW = 0
    case ADD = 1
    case EDIT = 2
}

struct VectorMetaData {
    let color: String
    let iconUrl: String
    let recordId: String
    let recordTypeId: String
}

enum LayoutVector {
    case PIN(point: CGPoint)
    case PATH(points: [CGPoint]) // Rect or Polygon (future version suppport)
    case ELLIPSE(points: [CGPoint], cornerRadius: CGFloat)
}
// let ellipse = UIBezierPath(roundedRect: frame, cornerRadius: shapeSize)
// We'll save points and draw rectframe with corner radii so we can get the ellipse shape

struct LayoutMapData {
    let vector: LayoutVector
    let metaData: VectorMetaData
}

struct InputBundle {
    let layoutUrl: String
    let mode: EnumLayoutMapActivity
    let layoutData: [LayoutMapData] // empty array if no shape/pin exists in the map
}

