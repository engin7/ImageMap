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
    case ELLIPSE(points: [CGPoint]) // operation is different here even data model is same!
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
    let layoutData: LayoutMapData? // empty array if no shape/pin exists in the map
}

// MOCK DATABASE

struct OutputBundle {
    let layoutName: String // to show in table
    let layoutUrl: String
    var layoutData = [LayoutMapData]() // empty array if no shape/pin exists in the map
}

class DataBase {
    static let shared = DataBase()
    var layouts = [OutputBundle]()
    init() {
        add()
    }
    
    func add() {
        
        let record0 = OutputBundle(layoutName: "MIT", layoutUrl: "https://ci.mit.edu/sites/default/files/images/Map-smaller2.png")
        let record1 = OutputBundle(layoutName: "Harvard", layoutUrl: "https://www.georgeglazer.com/wpmain/wp-content/uploads/2017/02/garfield-harvard-det1.jpg")
        let record2 = OutputBundle(layoutName: "Stanford", layoutUrl: "")
        let record3 = OutputBundle(layoutName: "Princeton", layoutUrl: "")
        
        layouts.append(record0)
        layouts.append(record1)
        layouts.append(record2)
        layouts.append(record3)
        
    }
    
}

 
 
