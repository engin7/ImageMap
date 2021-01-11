//
//  ViewController.swift
//  ImageMap
//
//  Created by Engin KUK on 11.01.2021.
//

import UIKit

@available(iOS 13.0, *)
class ViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewTrailingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBAction func clearPressed(_ sender: Any) {
        imageView.subviews.forEach({ $0.removeFromSuperview() })
    }
    
    var longPressRecognizer: UILongPressGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(scrollViewDoubleTapped))
        doubleTapRecognizer.numberOfTapsRequired = 2
        doubleTapRecognizer.numberOfTouchesRequired = 1
        scrollView.addGestureRecognizer(doubleTapRecognizer)
        
        longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed))
        scrollView.addGestureRecognizer(longPressRecognizer)

    }

    @objc func longPressed(gesture: UILongPressGestureRecognizer) {
        let touchPoint = longPressRecognizer.location(in: imageView)
      
             if gesture.state == UIGestureRecognizer.State.began {
                addTag(withLocation: touchPoint, toPhoto: imageView)
             } else {
                ///
             }
         
    }
     
    func addTag(withLocation location: CGPoint, toPhoto photo: UIImageView) {
        let frame = CGRect(x: location.x - 15, y: location.y - 15, width: 50, height: 50)
        let tempImageView = UIImageView(frame: frame)
        let tintableImage = UIImage(systemName: "pin.circle.fill")?.withRenderingMode(.alwaysTemplate)
        tempImageView.image = tintableImage
        tempImageView.tintColor = .red //will be options
        photo.addSubview(tempImageView)
        
        let label = UILabel(frame: CGRect(x: location.x + 35, y: location.y - 30, width: 250, height: 50))
        label.textColor = UIColor.blue
        label.text = "(\(Double(round(1000*location.x)/1000)), \(Double(round(1000*location.y)/1000)))"
        photo.addSubview(label)

    }

    override func viewWillLayoutSubviews() {
      super.viewWillLayoutSubviews()
      updateMinZoomScaleForSize(view.bounds.size)
    }

    
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

@available(iOS 13.0, *)
extension ViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateConstraintsForSize(view.bounds.size)
    }
  
    @objc func scrollViewDoubleTapped(recognizer: UITapGestureRecognizer) {
      // 1
        let pointInView = recognizer.location(in: imageView)

      // 2
      var newZoomScale = scrollView.zoomScale * 1.5
      newZoomScale = min(newZoomScale, scrollView.maximumZoomScale)

      // 3
      let scrollViewSize = scrollView.bounds.size
      let w = scrollViewSize.width / newZoomScale
      let h = scrollViewSize.height / newZoomScale
      let x = pointInView.x - (w / 2.0)
      let y = pointInView.y - (h / 2.0)

    let rectToZoomTo = CGRect(x: x, y: y, width: w, height: h)
 
        scrollView.zoom(to: rectToZoomTo, animated: true)
    }
}
