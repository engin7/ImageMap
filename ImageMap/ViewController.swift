//
//  ViewController.swift
//  ImageMap
//
//  Created by Engin KUK on 11.01.2021.
//

import UIKit

// can be removed after changing system Images
@available(iOS 13.0, *)
class ViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewTrailingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBAction func clearPressed(_ sender: Any) {
        imageView.subviews.forEach({ $0.removeFromSuperview() })
        imageView.layer.sublayers?.removeAll()
    }
    
    var longPressRecognizer: UILongPressGestureRecognizer!
    var singleTapRecognizer: UITapGestureRecognizer!
    let notificationCenter = NotificationCenter.default
 
    var startPoint: CGPoint?
    var touchedPoint: CGPoint?
    var selectedLayer: CAShapeLayer?
    var movingRect = false
     
    let rectShapeLayer: CAShapeLayer = {
          let shapeLayer = CAShapeLayer()
          shapeLayer.strokeColor = UIColor.black.cgColor
          shapeLayer.fillColor = UIColor.clear.cgColor
          shapeLayer.lineWidth = 5
          shapeLayer.lineDashPattern = [47.12]
          return shapeLayer
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(scrollViewDoubleTapped))
        doubleTapRecognizer.numberOfTapsRequired = 2
        doubleTapRecognizer.numberOfTouchesRequired = 1
        scrollView.addGestureRecognizer(doubleTapRecognizer)
        
        longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed))
        scrollView.addGestureRecognizer(longPressRecognizer)
        
        singleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tagTapped))
        singleTapRecognizer.numberOfTouchesRequired = 1
        scrollView.addGestureRecognizer(singleTapRecognizer)
        
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)

        if notification.name == UIResponder.keyboardWillHideNotification {
            scrollView.contentInset = .zero
        } else {
            scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
        }

        scrollView.scrollIndicatorInsets = scrollView.contentInset

    }
    
    @objc func longPressed(gesture: UILongPressGestureRecognizer) {
             
             if gesture.state == UIGestureRecognizer.State.began {
                
               startPoint = nil
               startPoint = longPressRecognizer.location(in: imageView)
                
                imageView.layer.sublayers?.forEach { layer in
                    let layer = layer as? CAShapeLayer
                    if let path = layer?.path, path.contains(startPoint!) {
                        movingRect = true
                    }
                }
               if !movingRect {
                    imageView.layer.addSublayer(rectShapeLayer)
                }
                touchedPoint = startPoint
               
             } else if gesture.state == UIGestureRecognizer.State.changed {
                
                let currentPoint = longPressRecognizer.location(in: imageView)
                if movingRect {
                   
                    let xOffset = currentPoint.x - touchedPoint!.x
                    let yOffset = currentPoint.y - touchedPoint!.y
                    
                imageView.layer.sublayers?.forEach { layer in
                    let layer = layer as? CAShapeLayer
                        if let path = layer?.path, path.contains(currentPoint) {
                            if (selectedLayer == nil) {
                                selectedLayer = layer!
                            }
                        }
                   }
                    // apply offset to out drawn path
                    var translation = CGAffineTransform(translationX: xOffset,y: yOffset)
                    let path = selectedLayer?.path?.copy(using: &translation)
                    selectedLayer?.path = path
                    // highlight moving rect
                    let color = UIColor(red: 0, green: 0, blue: 1, alpha: 0.2).cgColor
                    selectedLayer?.fillColor? = color
                   }
                if !movingRect {
                    let frame = rect(from: startPoint!, to: currentPoint)
                    rectShapeLayer.path = UIBezierPath(rect: frame).cgPath
                  }
                touchedPoint = currentPoint
             } else if gesture.state == UIGestureRecognizer.State.ended {
                let currentPoint = longPressRecognizer.location(in: imageView)
                let middlePoint = CGPoint(x: (currentPoint.x + startPoint!.x)/2, y: (currentPoint.y + startPoint!.y)/2)
                if !movingRect {
                    let rectLayer = CAShapeLayer()
                    rectLayer.strokeColor = UIColor.black.cgColor
                    rectLayer.fillColor = UIColor.clear.cgColor
                    rectLayer.lineWidth = 5
                    rectLayer.path = rectShapeLayer.path
                    imageView.layer.addSublayer(rectLayer)
                    rectShapeLayer.path = nil
                    addTag(withLocation: middlePoint, toPhoto: imageView)
                 }
                movingRect = false
                selectedLayer = nil // ot chose new layers
             }
    }
     
    func addTag(withLocation location: CGPoint, toPhoto photo: UIImageView) {
        let frame = CGRect(x: location.x - 15, y: location.y - 15, width: 50, height: 50)
        let tempImageView = UIImageView(frame: frame)
        let tintableImage = UIImage(systemName: "pin.circle.fill")?.withRenderingMode(.alwaysTemplate)
        tempImageView.image = tintableImage
        tempImageView.tintColor = .cyan //will be options
        tempImageView.isUserInteractionEnabled = true
        
        let label = UILabel(frame: CGRect(x: 50, y: 0, width: 250, height: 30))
        label.textColor = UIColor.cyan
        label.text = "(\(Double(round(1000*location.x)/1000)), \(Double(round(1000*location.y)/1000)))"
        tempImageView.addSubview(label)
        
        let textField = UITextField(frame: CGRect(x: 50, y: -25, width: 250, height: 150))
        tempImageView.addSubview(textField)
        textField.delegate = self
        textField.isUserInteractionEnabled = true
        textField.textColor = .cyan
         
        photo.addSubview(tempImageView)
        textField.becomeFirstResponder()
    }
    
    @objc func tagTapped(gesture: UITapGestureRecognizer) {
        let touchPoint = singleTapRecognizer.location(in: imageView)
       
        let subviewTapped = getSubViewTouched(touchPoint: touchPoint)
        subviewTapped.subviews.forEach({ $0.isHidden = !$0.isHidden })
          // process subviewTapped however you want
        if subviewTapped.tintColor == .cyan {
            subviewTapped.tintColor = .red
        } else {
            subviewTapped.tintColor = .cyan
        }
          
    }
    
    func getSubViewTouched(touchPoint: CGPoint) -> UIView {
        
        let filteredSubviews = imageView.subviews.filter { subView -> Bool in
            return subView.frame.contains(touchPoint)
          }
        guard let subviewTapped = filteredSubviews.first else {
            return UIView()
        }
        return subviewTapped
    }
   
     
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
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
   
    private func rect(from: CGPoint, to: CGPoint) -> CGRect {
        return CGRect(x: min(from.x, to.x),
               y: min(from.y, to.y),
               width: abs(to.x - from.x),
               height: abs(to.y - from.y))
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
