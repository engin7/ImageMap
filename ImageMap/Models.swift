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
    case PATH(points: [CGPoint])
    case CIRCLE(point: CGPoint, radius: CGFloat) // ellipse ?? we draw rect circle
}

struct LayoutMapData {
    let vector: LayoutVector
    let metaData: VectorMetaData
}

struct InputBundle {
    let layoutUrl: String
    let mode: EnumLayoutMapActivity
    let layoutData: LayoutMapData?
}
