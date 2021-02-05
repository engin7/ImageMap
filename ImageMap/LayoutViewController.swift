//
//  LayoutViewController.swift
//  ImageMap
//
//  Created by Engin KUK on 31.01.2021.
//

import UIKit

class LayoutViewController: UIViewController, UIGestureRecognizerDelegate {
    
   var layout: OutputBundle?
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
   
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.loadImageUsingCache(urlString: layout?.layoutUrl ?? "")
        drawAllSavedItems()
        // Download image from URL
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(scrollViewDoubleTapped))
        doubleTapRecognizer.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTapRecognizer)
    }
    
    // MARK: - Helper method for drawing Shapes
    
    private func drawAllSavedItems() {
        if let layout = layout {
            for item in layout.layoutData {
                  drawShape(item)
                 
            }
        }
    }
     
    private func drawShape(_ item: LayoutMapData)   {
    
        let metaData = item.metaData
        let vector = item.vector
        
        let itemLayer = CAShapeLayer()
        itemLayer.strokeColor = UIColor.black.cgColor
        itemLayer.lineWidth = 4
        itemLayer.fillColor? = UIColor(hex: metaData.color)!.cgColor
        let thePath = UIBezierPath()

        switch vector {
        case .PIN(let point):
           
            let p = imageView.contentClippingPos(point: point)
            let iv = UIImageView(frame: imageView.frame)
            iv.dropPin(CGPoint(x: p.x, y: p.y-20))
            
            scrollView.addSubview(iv)
 
            print(point)
            print(p)
            
         case .PATH(let points):
            thePath.move(to: points[0])
            thePath.addLine(to: points[1])
            thePath.addLine(to: points[2])
            thePath.addLine(to: points[3])
            thePath.close()
           
        case .ELLIPSE(let points):
               // TODO: add this to Extensions later.
            var frame = CGRect()
            let w = points[2].distance(to: points[1])
            let h = points[1].distance(to: points[0])
            
            if points[0].x < points[3].x &&  points[0].y < points[1].y {
                frame = CGRect(x: points[0].x, y: points[0].y, width: w, height: h)
            }  else if points[0].y > points[1].y && points[0].x > points[3].x {
                frame = CGRect(x: points[2].x, y: points[2].y, width: w, height: h)
            }  else if points[0].x > points[3].x {
                frame = CGRect(x: points[3].x, y: points[3].y, width: w, height: h)
            }  else if points[0].y > points[1].y {
                frame = CGRect(x: points[1].x, y: points[1].y, width: w, height: h)
            }
             
            let radii = min(frame.height, frame.width)
            
            let ellipsePath = UIBezierPath(roundedRect: frame, cornerRadius: radii)
            itemLayer.path = ellipsePath.cgPath
            imageView.layer.addSublayer(itemLayer)
            return
            default:
            print("..")
        }
        
            itemLayer.path = thePath.cgPath
            imageView.layer.addSublayer(itemLayer)
    }
    
}
 
extension LayoutViewController: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
   
  
    @objc func scrollViewDoubleTapped(recognizer: UITapGestureRecognizer) {
      
        let pointInView = recognizer.location(in: imageView)
 
      var newZoomScale = scrollView.zoomScale * 1.5
      newZoomScale = min(newZoomScale, scrollView.maximumZoomScale)
 
      let scrollViewSize = scrollView.bounds.size
      let w = scrollViewSize.width / newZoomScale
      let h = scrollViewSize.height / newZoomScale
      let x = pointInView.x - (w / 2.0)
      let y = pointInView.y - (h / 2.0)

    let rectToZoomTo = CGRect(x: x, y: y, width: w, height: h)
 
        scrollView.zoom(to: rectToZoomTo, animated: true)
    }
         
    // MARK: - ScrollView zoom, drag etc
 
    func updateMinZoomScaleForSize(_ size: CGSize) {
      let widthScale = size.width / imageView.bounds.width
      let heightScale = size.height / imageView.bounds.height
      let minScale = min(widthScale, heightScale)
        
      scrollView.minimumZoomScale = minScale
      scrollView.zoomScale = minScale
        
    }
   
}


extension UIImageView {
    func contentClippingPos(point: CGPoint) -> CGPoint {
        guard let image = image else { return .zero }
        guard contentMode == .scaleAspectFit else { return .zero }
        guard image.size.width > 0 && image.size.height > 0 else { return .zero }

        let scale: CGFloat
        if image.size.width > image.size.height {
            scale = bounds.width / image.size.width
        } else {
            scale = bounds.height / image.size.height
        }

        let x =  (point.x * scale)
        let y =  (point.y * scale)

        return CGPoint(x: x, y: y)
    }
    
    func dropPin(_ point: CGPoint)  {
               
                let color = UIColor(ciColor: .red)
                UIGraphicsBeginImageContext(self.frame.size)
                guard let context = UIGraphicsGetCurrentContext() else { return }
                context.saveGState()
                context.setStrokeColor(color.cgColor)
                context.setFillColor(color.cgColor)
                context.setLineWidth(2)
                context.move(to: point)
                let lineEnd: CGPoint = .init(x: point.x, y: point.y - 25.0)
                context.addLine(to: lineEnd)
                context.addEllipse(in: .init(x: lineEnd.x-5, y: lineEnd.y - 5.0, width: 10.0, height: 10.0))
                context.drawPath(using: .fillStroke)
                context.restoreGState()
                if let img = UIGraphicsGetImageFromCurrentImageContext() {
                   image = img
                    UIGraphicsEndImageContext()
                }
                 
    }
    
}

