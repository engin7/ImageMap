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
    var dragPoint: CAShapeLayer.dragPoint?
    var selectedLayer: CAShapeLayer?
    var insideExistingRect = false
    var insideExistingPin = false
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
                let handPoint = CGPoint(x: startPoint!.x, y: startPoint!.y-50)
                handImageView?.frame.origin = handPoint
                handImageView?.frame.size = CGSize(width: 50, height: 50)
                self.imageView.addSubview(handImageView!)
                // check if inside rect
                imageView.layer.sublayers?.forEach { layer in
                    let layer = layer as? CAShapeLayer
                    if let path = layer?.path, path.contains(startPoint!) {
                        subviewTapped = getSubViewSelected(bounds: (layer?.path!.boundingBox)!)
                        let labels = subviewTapped?.subviews.compactMap { $0 as? UILabel }
                        subLabel = labels?.first
                        dragPoint = layer?.resizingStartPoint(startPoint, in: layer!)
                        print(dragPoint) // detect edge/corners
                        insideExistingRect = true
                    }
                }
                 
               if !insideExistingRect {
                if let pinTapped = getSubViewTouched(touchPoint: startPoint!) {
                    // inside a pin
                    subviewTapped = pinTapped
                    let labels = subviewTapped?.subviews.compactMap { $0 as? UILabel }
                    subLabel = labels?.first
                    print("INSIDE A PIN *****")
                    insideExistingPin = true
                } else {
                    imageView.layer.addSublayer(rectShapeLayer)
                }
               } else {
                // check drag point inside the pin
                    switch dragPoint {
                case .noResizing: //moving
                    handImageView!.image = UIImage(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                 case .isResizingLeftEdge:
                     handImageView!.image = UIImage(systemName: "arrow.left.and.right")
                    let handPoint = CGPoint(x: startPoint!.x-60, y: startPoint!.y-50)
                    handImageView?.frame.origin = handPoint
                 case .isResizingRightEdge:
                    handImageView!.image = UIImage(systemName: "arrow.left.and.right")
                    let handPoint = CGPoint(x: startPoint!.x+10, y: startPoint!.y-50)
                    handImageView?.frame.origin = handPoint
                case .isResizingBottomEdge:
                    handImageView!.image = UIImage(systemName: "arrow.up.and.down")
                    let handPoint = CGPoint(x: startPoint!.x, y: startPoint!.y-50)
                    handImageView?.frame.origin = handPoint
                case .isResizingTopEdge:
                    handImageView!.image = UIImage(systemName: "arrow.up.and.down")
                    let handPoint = CGPoint(x: startPoint!.x, y: startPoint!.y-60)
                    handImageView?.frame.origin = handPoint
                // corner cases
                case .isResizingLeftCorner:
                    handImageView!.image = UIImage(systemName: "arrow.up.left.and.arrow.down.right")
                case .isResizingRightCorner:
                    let image = UIImage(systemName: "arrow.up.left.and.arrow.down.right")!.rotate(radians: .pi/2)
                    handImageView!.image = image
                case .isResizingBottomLeftCorner:
                    let image = UIImage(systemName: "arrow.up.left.and.arrow.down.right")!.rotate(radians: .pi/2)
                    handImageView!.image = image
                case .isResizingBottomRightCorner:
                    handImageView!.image = UIImage(systemName: "arrow.up.left.and.arrow.down.right")
                case .none:
                    break
                }
            
               }
                touchedPoint = startPoint
               
             } else if gesture.state == UIGestureRecognizer.State.changed {
                
                let currentPoint = longPressRecognizer.location(in: imageView)
                let xOffset = currentPoint.x - touchedPoint!.x
                let yOffset = currentPoint.y - touchedPoint!.y
                
                if insideExistingRect && !insideExistingPin {
                 
                imageView.layer.sublayers?.forEach { layer in
                    let layer = layer as? CAShapeLayer
                        if let path = layer?.path, path.contains(currentPoint) {
                            if (selectedLayer == nil) {
                                selectedLayer = layer!
                                  
                            }
                        }
                   }
                    var translation = CGAffineTransform()
                    var translateBack = CGAffineTransform()

                    guard let pathBox = selectedLayer?.path?.boundingBox else {return}
                    let center = CGPoint(x: pathBox.midX, y: pathBox.midY)
                     // apply offset to out drawn path
                    // https://stackoverflow.com/a/20322817/8707120
                 
                    switch dragPoint {
                    case .noResizing:
                        translation = CGAffineTransform(translationX: xOffset,y: yOffset)
                        translateBack = CGAffineTransform(translationX: 0, y: 0)
                     case .isResizingLeftEdge:
                        // xoffset negative
                        translation = CGAffineTransform(scaleX: 1 - xOffset/pathBox.size.width, y: 1).translatedBy(x: -center.x, y: -center.y)
                        translateBack = CGAffineTransform(translationX: xOffset/2 + center.x, y: center.y)
                    case .isResizingRightEdge:
                        translation = CGAffineTransform(scaleX: 1 + xOffset/pathBox.size.width, y: 1).translatedBy(x: -center.x, y: -center.y)
                        translateBack = CGAffineTransform(translationX: xOffset/2 + center.x, y: center.y)
                    case .isResizingBottomEdge:
                        translation = CGAffineTransform(scaleX: 1, y: 1 + yOffset/pathBox.size.height).translatedBy(x: -center.x, y: -center.y)
                        translateBack = CGAffineTransform(translationX: center.x, y: center.y + yOffset/2)
                    case .isResizingTopEdge:
                        translation = CGAffineTransform(scaleX: 1, y: 1 - yOffset/pathBox.size.height).translatedBy(x: -center.x, y: -center.y)
                        translateBack = CGAffineTransform(translationX: center.x, y: center.y + yOffset/2)
                    // corner cases
                    case .isResizingLeftCorner:
                        translation = CGAffineTransform(scaleX: 1 - xOffset/pathBox.size.width, y: 1 - yOffset/pathBox.size.height).translatedBy(x: -center.x, y: -center.y)
                        translateBack = CGAffineTransform(translationX: center.x + xOffset/2, y: center.y + yOffset/2)
                    case .isResizingRightCorner:
                        translation = CGAffineTransform(scaleX: 1 + xOffset/pathBox.size.width, y: 1 - yOffset/pathBox.size.height).translatedBy(x: -center.x, y: -center.y)
                        translateBack = CGAffineTransform(translationX: center.x + xOffset/2, y: center.y + yOffset/2)
                    case .isResizingBottomLeftCorner:
                        translation = CGAffineTransform(scaleX: 1 - xOffset/pathBox.size.width, y: 1 + yOffset/pathBox.size.height).translatedBy(x: -center.x, y: -center.y)
                        translateBack = CGAffineTransform(translationX: center.x + xOffset/2, y: center.y + yOffset/2)
                    case .isResizingBottomRightCorner:
                        translation = CGAffineTransform(scaleX: 1 + xOffset/pathBox.size.width, y: 1 + yOffset/pathBox.size.height).translatedBy(x: -center.x, y: -center.y)
                        translateBack = CGAffineTransform(translationX: center.x + xOffset/2, y: center.y + yOffset/2)
                    
                    case .none:
                        break
                    }
                     
                    let path = selectedLayer?.path?.copy(using: &translation)
                    selectedLayer?.path = path
                     
                    let pathBack = selectedLayer?.path?.copy(using: &translateBack)
                    selectedLayer?.path = pathBack
                    
                    // highlight moving/resizing rect
                    let color = UIColor(red: 0, green: 0, blue: 1, alpha: 0.2).cgColor
                    selectedLayer?.fillColor? = color
                    // update tag
                    guard let midX = selectedLayer?.path?.boundingBox.midX else { return }  // TODO: - reset values
                    guard let midY = selectedLayer?.path?.boundingBox.midY else { return }
                    let midPoint = CGPoint(x: midX, y: midY)
                    subviewTapped?.center = midPoint
                    subLabel?.text = "(\(Double(round(1000*midX)/1000)), \(Double(round(1000*midY)/1000)))"
                   }
                if !insideExistingRect && !insideExistingPin {
                    let frame = rect(from: startPoint!, to: currentPoint)
                    rectShapeLayer.path = UIBezierPath(rect: frame).cgPath
                  }
                if insideExistingPin {
                    subviewTapped?.center = currentPoint
                    subLabel?.text = "(\(Double(round(1000*currentPoint.x)/1000)), \(Double(round(1000*currentPoint.y)/1000)))"
                }
                    handImageView?.frame = (handImageView?.frame.offsetBy(dx: xOffset, dy: yOffset))!
                    touchedPoint = currentPoint
             } else if gesture.state == UIGestureRecognizer.State.ended {
            
                let currentPoint = longPressRecognizer.location(in: imageView)
                let middlePoint = CGPoint(x: (currentPoint.x + startPoint!.x)/2, y: (currentPoint.y + startPoint!.y)/2)
                if !insideExistingRect && !insideExistingPin {
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
                insideExistingRect = false
                insideExistingPin = false
                dragPoint = CAShapeLayer.dragPoint.noResizing
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
       
        if let subviewTapped = getSubViewTouched(touchPoint: touchPoint) {
        subviewTapped.subviews.forEach({ $0.isHidden = !$0.isHidden })
          
        // TODO - add tint color selection
        if subviewTapped.tintColor == .cyan {
            subviewTapped.tintColor = .red
        } else {
            subviewTapped.tintColor = .cyan
        }
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
    
    func getSubViewTouched(touchPoint: CGPoint) -> UIView? {
        
        let filteredSubviews = imageView.subviews.filter { subView -> Bool in
            return subView.frame.contains(touchPoint)
          }
        guard let subviewTapped = filteredSubviews.first else {
            return nil
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
extension CAShapeLayer {
 
    static var kResizeThumbSize:CGFloat = 44.0
    private typealias `Self` = CAShapeLayer
 
    enum dragPoint {
    // edges
    case isResizingLeftEdge
    case isResizingRightEdge
    case isResizingTopEdge
    case isResizingBottomEdge
    // corners
    case isResizingBottomRightCorner
    case isResizingLeftCorner
    case isResizingRightCorner
    case isResizingBottomLeftCorner
     
    case noResizing
        
    init() {
        self = .noResizing
        }
    }
 
    func resizingStartPoint(_ touch: CGPoint?,in layer: CAShapeLayer) -> dragPoint {
        
        var dragP = dragPoint()

        if let touch = touch {
            
            if ((layer.path?.boundingBox.maxY)! - touch.y < Self.kResizeThumbSize) && ((layer.path?.boundingBox.maxX)! - touch.x < Self.kResizeThumbSize) {
                dragP = dragPoint.isResizingBottomRightCorner
            } else if (touch.x - (layer.path?.boundingBox.minX)! < Self.kResizeThumbSize) && (touch.y - (layer.path?.boundingBox.minY)! < Self.kResizeThumbSize) {
                dragP = dragPoint.isResizingLeftCorner
            } else if ((layer.path?.boundingBox.maxX)! - touch.x < Self.kResizeThumbSize) && (touch.y - (layer.path?.boundingBox.minY)! < Self.kResizeThumbSize) {
               dragP = dragPoint.isResizingRightCorner
           } else if (touch.x - (layer.path?.boundingBox.minX)! < Self.kResizeThumbSize) && ((layer.path?.boundingBox.maxY)! - touch.y < Self.kResizeThumbSize) {
               dragP = dragPoint.isResizingBottomLeftCorner
           } else if (touch.x - (layer.path?.boundingBox.minX)! < Self.kResizeThumbSize) {
                dragP = dragPoint.isResizingLeftEdge
            } else if (touch.y - (layer.path?.boundingBox.minY)! < Self.kResizeThumbSize) {
                dragP = dragPoint.isResizingTopEdge
            } else if ((layer.path?.boundingBox.maxX)! - touch.x < Self.kResizeThumbSize) {
               dragP = dragPoint.isResizingRightEdge
           } else if ((layer.path?.boundingBox.maxY)! - touch.y < Self.kResizeThumbSize) {
               dragP = dragPoint.isResizingBottomEdge
           }
            
        }
        return dragP
    }
   
}

extension UIImage {
    func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        let context = UIGraphicsGetCurrentContext()!

        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        // Draw the image at its center
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
}
