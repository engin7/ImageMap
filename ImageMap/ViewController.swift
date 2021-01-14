//
//  ViewController.swift
//  ImageMap
//
//  Created by Engin KUK on 11.01.2021.
//

import UIKit

// TODO:  remove @available(iOS 13.0, *) after changing system Images (also in extension)
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
    var subviewTapped: UIView?
    var subLabel: UILabel?
    var handImageView: UIImageView?
    
    let rectShapeLayer: CAShapeLayer = {
          let shapeLayer = CAShapeLayer()
          shapeLayer.strokeColor = UIColor.black.cgColor
          shapeLayer.fillColor = UIColor.clear.cgColor
          shapeLayer.lineWidth = 4
          shapeLayer.lineDashPattern = [10,5,5,5]
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
   
    // MARK: - Long Press Gesture Logic
    @objc func longPressed(gesture: UILongPressGestureRecognizer) {
             
             if gesture.state == UIGestureRecognizer.State.began {
                
               startPoint = nil
               startPoint = longPressRecognizer.location(in: imageView)
                let handImg = UIImage(systemName: "hand.tap.fill")
                handImageView = UIImageView(image: handImg)
                let handPoint = CGPoint(x: startPoint!.x-20, y: startPoint!.y-20)
                handImageView?.frame.origin = handPoint
                handImageView?.frame.size = CGSize(width: 40, height: 40)
                self.imageView.addSubview(handImageView!)
                
                imageView.layer.sublayers?.forEach { layer in
                    let layer = layer as? CAShapeLayer
                    if let path = layer?.path, path.contains(startPoint!) {
                        subviewTapped = getSubViewSelected(bounds: (layer?.path!.boundingBox)!)
                        let labels = subviewTapped?.subviews.compactMap { $0 as? UILabel }
                        subLabel = labels?.first
                        movingRect = true
                    }
                }
               if !movingRect {
                    imageView.layer.addSublayer(rectShapeLayer)
                }
                touchedPoint = startPoint
               
             } else if gesture.state == UIGestureRecognizer.State.changed {
                
                let currentPoint = longPressRecognizer.location(in: imageView)
                let xOffset = currentPoint.x - touchedPoint!.x
                let yOffset = currentPoint.y - touchedPoint!.y
                
                if movingRect {
                 
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
                    // update tag
                    let midX = selectedLayer?.path?.boundingBox.midX
                    let midY = selectedLayer?.path?.boundingBox.midY
                    let midPoint = CGPoint(x: midX!, y: midY!)
                    subviewTapped?.center = midPoint
                    subLabel?.text = "(\(Double(round(1000*midX!)/1000)), \(Double(round(1000*midY!)/1000)))"
                   }
                if !movingRect {
                    let frame = rect(from: startPoint!, to: currentPoint)
                    rectShapeLayer.path = UIBezierPath(rect: frame).cgPath
                  }
                    handImageView?.frame = (handImageView?.frame.offsetBy(dx: xOffset, dy: yOffset))!
                    touchedPoint = currentPoint
             } else if gesture.state == UIGestureRecognizer.State.ended {
                let currentPoint = longPressRecognizer.location(in: imageView)
                let middlePoint = CGPoint(x: (currentPoint.x + startPoint!.x)/2, y: (currentPoint.y + startPoint!.y)/2)
                if !movingRect {
                    let rectLayer = CAShapeLayer()
                    rectLayer.strokeColor = UIColor.black.cgColor
                    rectLayer.fillColor = UIColor.clear.cgColor
                    rectLayer.lineWidth = 4
                    rectLayer.path = rectShapeLayer.path
                    imageView.layer.addSublayer(rectLayer)
                    rectShapeLayer.path = nil
                    addTag(withLocation: middlePoint, toPhoto: imageView)
                 }
                selectedLayer?.fillColor = UIColor.clear.cgColor
                movingRect = false
                selectedLayer = nil // ot chose new layers
                subLabel = nil
                handImageView!.removeFromSuperview()
             }
    }
    
    // MARK: Helper method for drawing
    
     private func rect(from: CGPoint, to: CGPoint) -> CGRect {
         return CGRect(x: min(from.x, to.x),
                y: min(from.y, to.y),
                width: abs(to.x - from.x),
                height: abs(to.y - from.y))
     }
    
    // MARK: - Adding Tag

    func addTag(withLocation location: CGPoint, toPhoto photo: UIImageView) {
        let frame = CGRect(x: location.x, y: location.y, width: 40, height: 40)
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
    
    // MARK: - Tapping Tag

    @objc func tagTapped(gesture: UITapGestureRecognizer) {
        let touchPoint = singleTapRecognizer.location(in: imageView)
       
        let subviewTapped = getSubViewTouched(touchPoint: touchPoint)
        subviewTapped.subviews.forEach({ $0.isHidden = !$0.isHidden })
          
        // TODO - add tint color selection
        if subviewTapped.tintColor == .cyan {
            subviewTapped.tintColor = .red
        } else {
            subviewTapped.tintColor = .cyan
        }
        
        // Highlighting rect
        imageView.layer.sublayers?.forEach { layer in
            let layer = layer as? CAShapeLayer
            if let path = layer?.path, path.contains(touchPoint) {
                let color = UIColor(red: 0, green: 1, blue: 0, alpha: 0.2).cgColor
                layer?.fillColor? = color
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    layer?.fillColor? = UIColor.clear.cgColor
                }
            }
        }
        
    }
    // MARK: - Get Subviews from clicked area

    func getSubViewSelected(bounds: CGRect) -> UIView {
        
        let filteredSubviews = imageView.subviews.filter { subView -> Bool in
            return bounds.contains(subView.frame)
          }
        guard let subviewTapped = filteredSubviews.first else {
            return UIView()
        }
        return subviewTapped
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
    // MARK: - ScrollView zoom, drag etc

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
    
}

// TODO: - Resizing

// touch on edges,corners
class Overlayer: CAShapeLayer {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */


    static var kResizeThumbSize:CGFloat = 44.0
    private typealias `Self` = Overlayer

    var imageView = UIImageView()

    var isResizingLeftEdge:Bool = false
    var isResizingRightEdge:Bool = false
    var isResizingTopEdge:Bool = false
    var isResizingBottomEdge:Bool = false

    var isResizingBottomRightCorner:Bool = false
    var isResizingLeftCorner:Bool = false
    var isResizingRightCorner:Bool = false
    var isResizingBottomLeftCorner:Bool = false


        //Define your initialisers here

    func resizing(_ touch: CGPoint?,in imageView: UIImageView) {
        if let touch = touch {
            
            isResizingBottomRightCorner = (imageView.bounds.size.width - touch.x < Self.kResizeThumbSize && imageView.bounds.size.height - touch.y < Self.kResizeThumbSize);
            isResizingLeftCorner = (touch.x < Self.kResizeThumbSize && touch.y < Self.kResizeThumbSize);
            isResizingRightCorner = (imageView.bounds.size.width-touch.x < Self.kResizeThumbSize && touch.y < Self.kResizeThumbSize);
            isResizingBottomLeftCorner = (touch.x < Self.kResizeThumbSize && imageView.bounds.size.height - touch.y < Self.kResizeThumbSize);

            isResizingLeftEdge = (touch.x < Self.kResizeThumbSize)
            isResizingTopEdge = (touch.y < Self.kResizeThumbSize)
            isResizingRightEdge = (imageView.bounds.size.width - touch.x < Self.kResizeThumbSize)

            isResizingBottomEdge = (self.bounds.size.height - touch.y < Self.kResizeThumbSize)

            // do something with your currentPoint

        }
    }
//
//    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//        if let touch = touches.first {
//            let currentPoint = touch.location(in: self)
//            // do something with your currentPoint
//        }
//    }
//        // finished
//    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        if let touch = touches.first {
//            let currentPoint = touch.location(in: self)
//            // do something with your currentPoint
//
//
//            isResizingLeftEdge = false
//             isResizingRightEdge = false
//             isResizingTopEdge = false
//             isResizingBottomEdge = false
//
//             isResizingBottomRightCorner = false
//             isResizingLeftCorner = false
//             isResizingRightCorner = false
//             isResizingBottomLeftCorner = false
//
//        }
//    }
}
