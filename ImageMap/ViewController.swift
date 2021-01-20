//
//  ViewController.swift
//  ImageMap
//
//  Created by Engin KUK on 11.01.2021.
//

import UIKit

// TODO:  remove @available(iOS 13.0, *) after changing system Images (also in extension)
@available(iOS 13.0, *)
class ViewController: UIViewController, UITextFieldDelegate, UIGestureRecognizerDelegate {
 
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                              shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
           return true
       }
    
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
     
    @IBOutlet weak var rectButton: UIBarButtonItem!
    @IBAction func rectButtonPressed(_ sender: Any) {
        switch drawingMode {
        case .drawRect:
            rectButton.tintColor = .systemBlue
            drawingMode = drawMode.noShape
        default:
            rectButton.tintColor = .red
            ellipseButton.tintColor = .systemBlue
            polygonButton.tintColor = .systemBlue
            drawingMode = drawMode.drawRect
        }
    }
    
    @IBOutlet weak var polygonButton: UIBarButtonItem!
    
    @IBAction func polygonButtonPressed(_ sender: Any) {
        switch drawingMode {
        case .drawPolygon:
            polygonButton.tintColor = .systemBlue
            drawingMode = drawMode.noShape
        default:
            polygonButton.tintColor = .red
            rectButton.tintColor = .systemBlue
            ellipseButton.tintColor = .systemBlue
            drawingMode = drawMode.drawPolygon
        }
    }
    
    @IBOutlet weak var ellipseButton: UIBarButtonItem!
    @IBAction func ellipseButtonPressed(_ sender: Any) {
        switch drawingMode {
        case .drawEllipse:
            ellipseButton.tintColor = .systemBlue
            drawingMode = drawMode.noShape
        default:
            ellipseButton.tintColor = .red
            rectButton.tintColor = .systemBlue
            polygonButton.tintColor = .systemBlue
            drawingMode = drawMode.drawEllipse
        }
    }
    
    var longPressRecognizer: UILongPressGestureRecognizer!
    var singleTapRecognizer: UITapGestureRecognizer!
    var rotationPanRecognizer : UIPanGestureRecognizer!
    let notificationCenter = NotificationCenter.default
 
    var startPoint: CGPoint?
    var touchedPoint: CGPoint?
    var dragPoint: CAShapeLayer.dragPoint?
    var selectedLayer: CAShapeLayer?
    var insideExistingShape = false
    var insideExistingPin = false
    var subviewTapped = UIView()
    var subLabel: UILabel?
    var handImageView = UIImageView()
    var overlayImageView = UIImageView()
    var cornersImageView: [UIImageView] = []
    var drawingMode = drawMode.noShape
    
    enum drawMode {
        case drawRect
        case drawPolygon
        case drawEllipse
        case noShape
    }
    
    let selectedShapeLayer: CAShapeLayer = {
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
        scrollView.addGestureRecognizer(doubleTapRecognizer)
        
        longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed))
        scrollView.addGestureRecognizer(longPressRecognizer)
        
        singleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tagTapped))
        scrollView.addGestureRecognizer(singleTapRecognizer)
        
        rotationPanRecognizer = UIPanGestureRecognizer(target: self, action: #selector(rotationTapped))
        rotationPanRecognizer.delegate = self
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(rotationPanRecognizer) // pan tutup surmek
         
        
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
                let handPoint = CGPoint(x: startPoint!.x-30, y: startPoint!.y-30)
                handImageView.frame.origin = handPoint
                handImageView.frame.size = CGSize(width: 30, height: 30)
                // careful! it can touch handView and use it as subview while checking with getSubViewTouched.
                self.imageView.addSubview(handImageView)
                 
                // check if inside rect
                imageView.layer.sublayers?.forEach { layer in
                    let layer = layer as? CAShapeLayer
                    if let path = layer?.path, path.contains(startPoint!) {
                        // if path contains startPoint or rotationPoint we're sure we're in a shape
                        
                        if let box =  layer?.path?.boundingBox {
                            subviewTapped = getSubViewSelected(bounds: box).first!
                        }
                         
                        let labels = subviewTapped.subviews.compactMap { $0 as? UILabel }
                        subLabel = labels.first
                        dragPoint = layer?.resizingStartPoint(startPoint, in: layer!)
                        print(dragPoint) // detect edge/corners
                        insideExistingShape = true
                    }
                }
                 
               if !insideExistingShape {
                if let pinTapped = getSubViewTouched(touchPoint: startPoint!), pinTapped != overlayImageView {
                    // inside a pin
                    subviewTapped = pinTapped
                    let labels = subviewTapped.subviews.compactMap { $0 as? UILabel }
                    subLabel = labels.first
                    print("INSIDE A PIN *****")
                    insideExistingPin = true
                    handImageView.image = UIImage(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                } else {
                    // add shape layer
                    imageView.layer.addSublayer(selectedShapeLayer)
                }
               } else {
                // check drag point inside the pin
                    switch dragPoint {
                case .noResizing: //moving
                    handImageView.image = UIImage(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                 case .isResizingLeftEdge:
                     handImageView.image = #imageLiteral(resourceName: "arrowLeftRightSides")
                    let handPoint = CGPoint(x: startPoint!.x-50, y: startPoint!.y)
                    handImageView.frame.origin = handPoint
                 case .isResizingRightEdge:
                    handImageView.image = #imageLiteral(resourceName: "arrowLeftRightSides")
                    let handPoint = CGPoint(x: startPoint!.x+20, y: startPoint!.y)
                    handImageView.frame.origin = handPoint
                case .isResizingBottomEdge:
                    handImageView.image = #imageLiteral(resourceName: "arrowTopBottomSides")
                    let handPoint = CGPoint(x: startPoint!.x, y: startPoint!.y+20)
                    handImageView.frame.origin = handPoint
                case .isResizingTopEdge:
                    handImageView.image = #imageLiteral(resourceName: "arrowTopBottomSides")
                    let handPoint = CGPoint(x: startPoint!.x, y: startPoint!.y-50)
                    handImageView.frame.origin = handPoint
                // corner cases
                case .isResizingLeftCorner:
                    handImageView.image = #imageLiteral(resourceName: "arrowLeftCorner")
                    let handPoint = CGPoint(x: startPoint!.x-50, y: startPoint!.y-50)
                    handImageView.frame.origin = handPoint
                case .isResizingRightCorner:
                    handImageView.image = #imageLiteral(resourceName: "arrowRightCorner")
                    let handPoint = CGPoint(x: startPoint!.x+25, y: startPoint!.y-50)
                    handImageView.frame.origin = handPoint
                case .isResizingBottomLeftCorner:
                    handImageView.image = #imageLiteral(resourceName: "arrowRightCorner")
                    let handPoint = CGPoint(x: startPoint!.x-50, y: startPoint!.y+25)
                    handImageView.frame.origin = handPoint
                case .isResizingBottomRightCorner:
                    handImageView.image = #imageLiteral(resourceName: "arrowLeftCorner")
                    let handPoint = CGPoint(x: startPoint!.x+25, y: startPoint!.y+25)
                    handImageView.frame.origin = handPoint
                case .none:
                    break
                }
            
               }
                touchedPoint = startPoint // offset reference
               // After start condition while keeping touch:
             } else if gesture.state == UIGestureRecognizer.State.changed {
                
                let currentPoint = longPressRecognizer.location(in: imageView)
                let xOffset = currentPoint.x - touchedPoint!.x
                let yOffset = currentPoint.y - touchedPoint!.y
                
                 // insede shape conditon
                if insideExistingShape && !insideExistingPin {
                 
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
                        print("no point")
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
                    guard let midX = selectedLayer?.path?.boundingBox.midX else { return }
                    guard let midY = selectedLayer?.path?.boundingBox.midY else { return }
                    let midPoint = CGPoint(x: midX, y: midY)
                    subviewTapped.center = midPoint
                    subLabel?.text = "(\(Double(round(1000*midX)/1000)), \(Double(round(1000*midY)/1000)))"
                     
                    guard let maxY = selectedLayer?.path?.boundingBox.maxY else { return }
                    guard let maxX = selectedLayer?.path?.boundingBox.maxX else { return }
                    // TODO: - Make rotation overlay image look nice while rotating. Right now it's getting bottom right values of all path points
                    overlayImageView.frame.origin = CGPoint(x: maxX, y: maxY)
                    
                   }
                if !insideExistingShape && !insideExistingPin {
                    // draw rectangle, ellipse etc according to selection
                    let path = drawShape(from: startPoint!, to: currentPoint, mode: drawingMode)
                    selectedShapeLayer.path = path.cgPath
                  }
                
                if insideExistingPin {
                    subviewTapped.center = currentPoint
                    subLabel?.text = "(\(Double(round(1000*currentPoint.x)/1000)), \(Double(round(1000*currentPoint.y)/1000)))"
                }
                    handImageView.frame = (handImageView.frame.offsetBy(dx: xOffset, dy: yOffset))
                    touchedPoint = currentPoint
             } else if gesture.state == UIGestureRecognizer.State.ended {
                 
                let currentPoint = longPressRecognizer.location(in: imageView)
                let middlePoint = CGPoint(x: (currentPoint.x + startPoint!.x)/2, y: (currentPoint.y + startPoint!.y)/2)
                if !insideExistingShape && !insideExistingPin {
                    if let width = selectedShapeLayer.path?.boundingBox.size.width  {
                        // just pin if size too small
                        if width < 5 {
                            addTag(withLocation: middlePoint, toPhoto: imageView)
                        } else {
                            let rectLayer = CAShapeLayer()
                            rectLayer.strokeColor = UIColor.black.cgColor
                            rectLayer.fillColor = UIColor.clear.cgColor
                            rectLayer.lineWidth = 4
                            rectLayer.path = selectedShapeLayer.path
                            imageView.layer.addSublayer(rectLayer)
                            addTag(withLocation: middlePoint, toPhoto: imageView)
                        }
                    } else {
                        // no rect drawn. Just add pin
                        addTag(withLocation: middlePoint, toPhoto: imageView)
                    }
                      selectedShapeLayer.path = nil
                    
                 }
                selectedLayer?.fillColor = UIColor.clear.cgColor
                insideExistingShape = false
                insideExistingPin = false
                dragPoint = CAShapeLayer.dragPoint.noResizing
                selectedLayer = nil // ot chose new layers
                subLabel = nil
                handImageView.removeFromSuperview()
             }
    }
    
    // MARK: - Helper method for drawing Shapes
    
    private func drawShape(from: CGPoint, to: CGPoint, mode: drawMode) -> UIBezierPath {
    
        let width = abs(to.x - from.x)
        let height = abs(to.y - from.y)
        let frame = CGRect(x: min(from.x, to.x),
                          y: min(from.y, to.y),
                          width: width,
                          height: height)
        
        let radius = sqrt(width * width + height * height)
        
        switch mode {
        case .drawRect:
            return UIBezierPath(rect: frame)
        case .drawPolygon:
            // TODO: make polygon possible
            return UIBezierPath(rect: frame)
        case .drawEllipse:
            return UIBezierPath(roundedRect: frame, cornerRadius: radius)
        default:
            return UIBezierPath()
        }
         
    }
    
     
    // MARK: - Adding Tag

    func addTag(withLocation location: CGPoint, toPhoto photo: UIImageView) {
        let frame = CGRect(x: location.x, y: location.y, width: 50, height: 50)
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

    @objc func tagTapped(gesture: UIRotationGestureRecognizer) {
        let touchPoint = singleTapRecognizer.location(in: imageView)
       
        // Highlighting rect
        imageView.layer.sublayers?.forEach { layer in
            let layer = layer as? CAShapeLayer
            if let path = layer?.path, path.contains(touchPoint) {
                let color = UIColor(red: 0, green: 1, blue: 0, alpha: 0.2).cgColor
                layer?.fillColor? = color
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    layer?.fillColor? = UIColor.clear.cgColor
                }
                // add the rotation and 4 corners image
                addRotationOverlay(layer)
                addCornersOverlay(layer)
            }
        }
        // subViews: pin, rotating overlay,
        
        if let subviewTapped = getSubViewTouched(touchPoint: touchPoint) {
            // hide label etc
        subviewTapped.subviews.forEach({ $0.isHidden = !$0.isHidden })
           
            if subviewTapped == overlayImageView {
                 
                // rotating button
                
            } else {
                // TODO - add tint color selection
                if subviewTapped.tintColor == .cyan {
                    subviewTapped.tintColor = .red
                } else {
                    subviewTapped.tintColor = .cyan
                }
            }
            
        }
      
    }
    
    // MARK: - Rotation logic
    
    @objc func rotationTapped(gesture: UIPanGestureRecognizer) {
    
        print("----- PAN")
        if gesture.state == UIGestureRecognizer.State.began {
            // TODO:
             // if clicked on rotation image cancel scrollView pangesture
            
        }
         
        let touchPoint = rotationPanRecognizer.location(in: imageView) //
        var selectedLayer = CAShapeLayer()
        // to be able to inside the layer path use shifted point
        let shiftedRotationPoint = CGPoint(x: touchPoint.x-50, y: touchPoint.y-50) // move left top corner of real touch point to make sure inside the path
        
        // Highlighting rect
        imageView.layer.sublayers?.forEach { layer in
            let layer = layer as? CAShapeLayer
            if let path = layer?.path, path.contains(shiftedRotationPoint) {
                let color = UIColor(red: 0, green: 1, blue: 0, alpha: 0.2).cgColor
                layer?.fillColor? = color
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    layer?.fillColor? = UIColor.clear.cgColor
                }
                selectedLayer = layer!
                scrollView.isScrollEnabled = false // disabled scroll
                //
            }
        }
        
        if gesture.state == UIGestureRecognizer.State.ended {
            
             // if clicked on rotation image cancel scrollView pangesture
            
            scrollView.isScrollEnabled = true // disabled scroll
        }
         
//        case .isRotating:
//            print("ROTATING")
//            if yOffset < 0 {
//                translation = CGAffineTransform(rotationAngle: 0.99*CGFloat.pi).translatedBy(x: -center.x, y: -center.y)
//            } else {
//                translation = CGAffineTransform(rotationAngle: -0.99*CGFloat.pi).translatedBy(x: -center.x, y: -center.y)
//            }
//            translateBack = CGAffineTransform(translationX: center.x, y: center.y)
//
        
    }
     
    func addRotationOverlay(_ layer: CAShapeLayer?) {
        let pathBox = layer?.path?.boundingBox
        guard let x = pathBox?.maxX else {return}
        guard let y = pathBox?.maxY else {return}
        let overlayOrigin = CGPoint(x: x, y: y) // right Corner
  
        overlayImageView.image = UIImage(systemName: "arrow.counterclockwise")
        overlayImageView.frame.origin = overlayOrigin
        overlayImageView.frame.size = CGSize(width: 50, height: 50)
        self.imageView.addSubview(overlayImageView)
      }
    
    func addCornersOverlay(_ layer: CAShapeLayer?) {
        // reset
        
        let pathBox = layer?.path?.boundingBox
        guard let xMax = pathBox?.maxX else {return}
        guard let yMax = pathBox?.maxY else {return}
        guard let xMin = pathBox?.minX else {return}
        guard let yMin = pathBox?.minY else {return}
        
        let rightBottomOrigin = CGPoint(x: xMax-15, y: yMax-15)
        let leftBottomOrigin = CGPoint(x: xMin-15, y: yMax-15)
        let rightTopOrigin = CGPoint(x: xMax-15, y: yMin-15)
        let leftTopOrigin = CGPoint(x: xMin-15, y: yMin-15)
        
        let corners = [rightBottomOrigin, leftBottomOrigin, rightTopOrigin, leftTopOrigin]
        
        if cornersImageView.count != 0 {
            for i in 0...3 {
                cornersImageView[i].removeFromSuperview()
                
            }
            cornersImageView = [] // reset
        }
         
        
        for i in 0...3 {
            
            let imageView = UIImageView(image: UIImage(systemName: "largecircle.fill.circle"))
            imageView.frame.origin = corners[i]
            imageView.frame.size = CGSize(width: 30, height: 30)
            self.imageView.addSubview(imageView)
            cornersImageView.append(imageView)
             
        }
          
   
      }
    
    
    
    // MARK: - Get Subviews from clicked area

    func getSubViewSelected(bounds: CGRect) -> [UIView] {
        
        let filteredSubviews = imageView.subviews.filter { subView -> Bool in
            return bounds.contains(subView.frame)
          }
         
        return filteredSubviews
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
    
    // rotation logic is inside pangesture not longpress
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
 
