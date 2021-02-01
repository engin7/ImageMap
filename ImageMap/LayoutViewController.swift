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
    
    private func drawShape(_ item: LayoutMapData)   {
    
        let metaData = item.metaData
        let vector = item.vector
        
        let itemLayer = CAShapeLayer()
        let thePath = UIBezierPath()
        itemLayer.strokeColor = UIColor.black.cgColor
        itemLayer.lineWidth = 4
        itemLayer.fillColor? = UIColor(hex: metaData.color)!.cgColor
 
        switch vector {
         case .PATH(let points):
            
            thePath.move(to: points[0])
            thePath.addLine(to: points[1])
            thePath.addLine(to: points[2])
            thePath.addLine(to: points[3])
            thePath.close()
        case .ELLIPSE(let points, let cornerRadius):
               // will do
            print("..")
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
