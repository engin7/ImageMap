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
    @IBOutlet weak var imageViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewTrailingConstraint: NSLayoutConstraint!
   
    override func viewDidLoad() {
        super.viewDidLoad()
        drawAllSavedItems()
        // Download image from URL
        imageView.loadImageUsingCache(urlString: layout?.layoutUrl ?? "")
        
        updateMinZoomScaleForSize(view.bounds.size)
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
    
    func dropPin(_ point: CGPoint) -> UIImage? {
                var image = UIImage()
                let color = UIColor(ciColor: .red)
                UIGraphicsBeginImageContext(scrollView.frame.size)
                
                guard let context = UIGraphicsGetCurrentContext() else { return nil}
                context.saveGState()
                context.setStrokeColor(color.cgColor)
                context.setLineWidth(5)
                context.move(to: point)
                let lineEnd: CGPoint = .init(x: point.x + 5.0, y: point.y - 48.0)
                context.addLine(to: lineEnd)
                context.addEllipse(in: .init(x: lineEnd.x - 24.0, y: lineEnd.y - 48.0, width: 48.0, height: 48.0))
                context.drawPath(using: .fillStroke)
                context.restoreGState()
                if let img = UIGraphicsGetImageFromCurrentImageContext() {
                   image = img
                    UIGraphicsEndImageContext()
                }
                
                return image
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
            let image = dropPin(point)
            let iv = UIImageView(image: image)
            scrollView.addSubview(iv)
            print(imageView.contentClippingRect )
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
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateConstraintsForSize(view.bounds.size)
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
    func updateConstraintsForSize(_ size: CGSize) {
        
        let yOffset = max(0, (size.height - imageView.frame.height) / 2)
        imageViewTopConstraint.constant = yOffset
        imageViewBottomConstraint.constant = yOffset
        
        let xOffset = max(0, (size.width - imageView.frame.width) / 2)
        imageViewLeadingConstraint.constant = xOffset
        imageViewTrailingConstraint.constant = xOffset
        
        view.layoutIfNeeded()
    }
}


extension UIImageView {
    var contentClippingRect: CGRect {
        guard let image = image else { return bounds }
        guard contentMode == .scaleAspectFit else { return bounds }
        guard image.size.width > 0 && image.size.height > 0 else { return bounds }

        let scale: CGFloat
        if image.size.width > image.size.height {
            scale = bounds.width / image.size.width
        } else {
            scale = bounds.height / image.size.height
        }

        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let x = (bounds.width - size.width) / 2.0
        let y = (bounds.height - size.height) / 2.0

        return CGRect(x: x, y: y, width: size.width, height: size.height)
    }
}
