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
        longPressRecognizer.isEnabled = true
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

    override func viewDidLayoutSubviews()
           {
           // don't forget to do this....is critical.
        selectedLayer?.anchorPoint = CGPoint(x: 0, y: 0)
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
   
    var startPoint = CGPoint.zero
    var touchedPoint = CGPoint.zero

    // MARK: - Long Press Gesture Logic
    @objc func longPressed(gesture: UILongPressGestureRecognizer) {
             
             if gesture.state == UIGestureRecognizer.State.began {
                
                  startPoint = longPressRecognizer.location(in: imageView)
                
                let handImg = UIImage(systemName: "hand.tap.fill")
                handImageView = UIImageView(image: handImg)
                let handPoint = CGPoint(x: startPoint.x-30, y: startPoint.y-30)
                handImageView.frame.origin = handPoint
                handImageView.frame.size = CGSize(width: 30, height: 30)
                // careful! it can touch handView and use it as subview while checking with getSubViewTouched.
//                self.imageView.addSubview(handImageView)
                 
                // check if inside rect
                imageView.layer.sublayers?.forEach { layer in
                    let layer = layer as? CAShapeLayer
                    if let path = layer?.path, path.contains(startPoint) {
                        // if path contains startPoint or rotationPoint we're sure we're in a shape
                        
                        if let box =  layer?.path?.boundingBox {
                            if let subView = getSubViewSelected(bounds: box).first {
                                subviewTapped = subView
                            }
                        }
                         
                        let labels = subviewTapped.subviews.compactMap { $0 as? UILabel }
                        subLabel = labels.first
                        dragPoint = layer?.resizingStartPoint(startPoint, in: layer!)
                        print(dragPoint) // detect edge/corners
                        insideExistingShape = true
                    }
                }
                 
               if !insideExistingShape {
                if let pinTapped = getSubViewTouched(touchPoint: startPoint), pinTapped != overlayImageView {
                    // inside a pin
                    subviewTapped = pinTapped
                    let labels = subviewTapped.subviews.compactMap { $0 as? UILabel }
                    subLabel = labels.first
                    print("INSIDE A PIN *****")
                    insideExistingPin = true
                    handImageView.image = UIImage(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                } else {
                    // add shape layer
                    // FIXME: for ipad when shape is small outside the image is  not be able to drawn. If you add layer to scrollView it's possible but you need to adjust coordinates
                    imageView.layer.addSublayer(selectedShapeLayer)
                }
               }
                touchedPoint = startPoint // offset reference
               // After start condition while keeping touch:
             } else if gesture.state == UIGestureRecognizer.State.changed {
                
                let currentPoint = longPressRecognizer.location(in: imageView)
                let xOffset = currentPoint.x - touchedPoint.x
                let yOffset = currentPoint.y - touchedPoint.y
                
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
                    
                    guard let pathBox = selectedLayer?.path?.boundingBox else {return}
                    let center = CGPoint(x: pathBox.midX, y: pathBox.midY)
                     // apply offset to out drawn path
                    // https://stackoverflow.com/a/20322817/8707120
                  
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
                    let path = drawShape(from: startPoint, to: currentPoint, mode: drawingMode)
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
                let middlePoint = CGPoint(x: (currentPoint.x + startPoint.x)/2, y: (currentPoint.y + startPoint.y)/2)
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
                             
                            let minX = rectLayer.path!.boundingBox.minX
                            let minY = rectLayer.path!.boundingBox.minY
                            let maxX = rectLayer.path!.boundingBox.maxX
                            let maxY = rectLayer.path!.boundingBox.maxY
                            
                            let lt = CGPoint(x: minX, y: minY)
                            let lb = CGPoint(x: minX, y: maxY)
                            let rb = CGPoint(x: maxX, y: maxY)
                            let rt = CGPoint(x: maxX, y: minY)

                            
                            let corners  = [(corner: cornerPoint.leftTop,point: lt), (corner: cornerPoint.leftBottom,point: lb), (corner: cornerPoint.rightBottom,point: rb), (corner: cornerPoint.rightTop,point: rt)]
                        
                            let layer = shapeInfo(shape: rectLayer, cornersArray: corners)
                            
                            allShapes.append(layer)
                            
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
                longPressRecognizer.isEnabled = false // remove later: to test PAN

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
    
    func CGPointDistanceSquared(from: CGPoint, to: CGPoint) -> CGFloat {
        return (from.x - to.x) * (from.x - to.x) + (from.y - to.y) * (from.y - to.y)
    }

    func CGPointDistance(from: CGPoint, to: CGPoint) -> CGFloat {
        return sqrt(CGPointDistanceSquared(from: from, to: to))
    }
    
    private func skewShape(_ corner: cornerPoint,_ withShift: CGFloat ) -> UIBezierPath {
        
        let thePath = UIBezierPath()
        
        guard let shape = selectedShapesInitial else { return thePath}
        guard let leftTop = shape.cornersArray.filter({ $0.corner == .leftTop }).first?.point  else { return thePath}
        guard let leftBottom = shape.cornersArray.filter({ $0.corner == .leftBottom }).first?.point else {return thePath}
        guard let rightBottom = shape.cornersArray.filter({ $0.corner == .rightBottom }).first?.point else {return thePath}
        guard let rightTop = shape.cornersArray.filter({ $0.corner == .rightTop }).first?.point else {return thePath}

        var newCorners: [(corner:cornerPoint,point:CGPoint)] = []
        switch corner {
            
        case .leftTop:
            let shiftedLeftTop = CGPoint(x: (leftTop.x + withShift), y: leftTop.y)
            
            thePath.move(to: shiftedLeftTop)
            thePath.addLine(to: leftBottom)
            thePath.addLine(to: rightBottom)
            thePath.addLine(to: rightTop)
             
            // save points
            newCorners.append((.leftTop, shiftedLeftTop))
            newCorners.append((.leftBottom, leftBottom))
            newCorners.append((.rightBottom, rightBottom))
            newCorners.append((.rightTop, rightTop))
            
         case .leftBottom:
            let shiftedLeftBottom = CGPoint(x: (leftBottom.x + withShift), y: leftBottom.y)
            
            thePath.move(to: leftTop)
            thePath.addLine(to: shiftedLeftBottom)
            thePath.addLine(to: rightBottom)
            thePath.addLine(to: rightTop)
             
            // save points
            newCorners.append((.leftTop, leftTop))
            newCorners.append((.leftBottom, shiftedLeftBottom))
            newCorners.append((.rightBottom, rightBottom))
            newCorners.append((.rightTop, rightTop))
        
         case .rightBottom:
             let shiftedRightBottom = CGPoint(x: rightBottom.x  + withShift, y: rightBottom.y)
             
            thePath.move(to: leftTop)
            thePath.addLine(to: leftBottom)
            thePath.addLine(to: shiftedRightBottom)
            thePath.addLine(to: rightTop)
           
            // save points
            newCorners.append((.leftTop, leftTop))
            newCorners.append((.leftBottom, leftBottom))
            newCorners.append((.rightBottom, shiftedRightBottom))
            newCorners.append((.rightTop, rightTop))
         
         case .rightTop:
             let shiftedRightTop = CGPoint(x: (rightTop.x + withShift), y: rightTop.y)

            thePath.move(to: leftTop)
            thePath.addLine(to: leftBottom)
            thePath.addLine(to: rightBottom)
            thePath.addLine(to: shiftedRightTop)
            
            // save points
            newCorners.append((.leftTop, leftTop))
            newCorners.append((.leftBottom, leftBottom))
            newCorners.append((.rightBottom, rightBottom))
            newCorners.append((.rightTop, shiftedRightTop))
          
        case .noCornersSelected:
          
            print("Corner NOT Selected")
            thePath.move(to: leftTop)
            thePath.addLine(to: leftBottom)
            thePath.addLine(to: rightBottom)
            thePath.addLine(to: rightTop)
        }
        
        thePath.close()
        
        if corner != .noCornersSelected {
            let shapeEdited = shapeInfo(shape: selectedLayer!, cornersArray: newCorners)
            selectedShape = shapeEdited
              
            var cornerArray: [CGPoint] = []
            newCorners.forEach{cornerArray.append($0.point)}
            moveCornerOverlay(corners:cornerArray)
        }
       
        return thePath
        
    }
    
    // MARK: - Adding Tag

    func addTag(withLocation location: CGPoint, toPhoto photo: UIImageView) {
        let frame = CGRect(x: location.x, y: location.y, width: 20, height: 20)
        let tempImageView = UIImageView(frame: frame)
        let tintableImage = UIImage(systemName: "pin.circle.fill")?.withRenderingMode(.alwaysTemplate)
        tempImageView.image = tintableImage
        tempImageView.tintColor = .red //will be options
        tempImageView.isUserInteractionEnabled = true
        
        let label = UILabel(frame: CGRect(x:30, y: 0, width: 250, height: 30))
        label.textColor = UIColor.red
        label.text = "(\(Double(round(1000*location.x)/1000)), \(Double(round(1000*location.y)/1000)))"
        tempImageView.addSubview(label)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            label.isHidden = true
        }
        photo.addSubview(tempImageView)
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
                if (selectedLayer == nil) {
                    selectedLayer = layer!
                    selectedShape =  allShapes.filter {
                        $0.shape == selectedLayer
                    }.first!
                    selectedShapesInitial = selectedShape
                }
                 
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
                if subviewTapped.tintColor == .red {
                    subviewTapped.tintColor = .systemBlue
                } else {
                    subviewTapped.tintColor = .red
                }
            }
            
        }
      
    }
    
    // MARK: - Rotation logic
    
    enum cornerPoint {
    // corners selected
        case leftTop
        case leftBottom
        case rightBottom
        case rightTop
        case noCornersSelected
        init() {
            self = .noCornersSelected
            }
    }
 
    // save shapes info in this struct
    struct shapeInfo {
        var shape: CAShapeLayer
        var cornersArray : [(corner: cornerPoint,point: CGPoint)]
        
        init(shape: CAShapeLayer, cornersArray: [(cornerPoint,CGPoint)] ) {
            self.shape = shape
            self.cornersArray = cornersArray
           }
    }
    
    var selectedShape: shapeInfo?
    var selectedShapesInitial: shapeInfo?
    var allShapes: [shapeInfo] = []
    var corner = cornerPoint()
    var panStartPoint = CGPoint.zero
    
    // FIXME: - CRASH WITHOUT RECTANGLE
    
    @objc func rotationTapped(gesture: UIPanGestureRecognizer) {
     
        if gesture.state == UIGestureRecognizer.State.began {
            
            
            panStartPoint = rotationPanRecognizer.location(in: imageView)
            // possiblePoints to detect rect
            let tl = CGPoint(x: panStartPoint.x-50, y: panStartPoint.y+50)
            let bl = CGPoint(x: panStartPoint.x+50, y: panStartPoint.y-50)
            let tr = CGPoint(x: panStartPoint.x+50, y: panStartPoint.y+50)
            let br = CGPoint(x: panStartPoint.x-50, y: panStartPoint.y-50)
            
                // TODO: - Refactor this point detection
            imageView.layer.sublayers?.forEach { layer in
                let layer = layer as? CAShapeLayer
                if let path = layer?.path, path.contains(tl) || path.contains(bl) || path.contains(tr) || path.contains(br) {
                        if (selectedLayer == nil) {
                            selectedLayer = layer!
                            selectedShape =  allShapes.filter {
                                $0.shape == selectedLayer
                            }.first!
                            selectedShapesInitial = selectedShape
                        }
                    }
               }
            
            if let subviewTapped = getSubViewTouched(touchPoint: panStartPoint) {

                scrollView.isScrollEnabled = false // disabled scroll

                if subviewTapped == overlayImageView {
                    // rotating button
                    print("INSIDE rot overlay")
                    corner = .noCornersSelected
                } else {
                    print("INSIDE CORNERS")
                    // corners or pin
                    if cornersImageView.count > 0 {
                        if subviewTapped == cornersImageView[0] {
                            corner = .leftTop
                        } else if subviewTapped == cornersImageView[1] {
                            corner = .leftBottom
                        } else if subviewTapped == cornersImageView[2] {
                            corner = .rightBottom
                        } else if subviewTapped == cornersImageView[3] {
                            corner = .rightTop
                        }
                    }
                        print(corner)
                        print("***** Touch started")
                }
                
            } else {
                corner = .noCornersSelected
            }
             
        }
 
        touchedPoint = panStartPoint // to offset reference
        
        if gesture.state == UIGestureRecognizer.State.changed && selectedShape != nil {
            // we're inside selection
            print("&&&&&&&  TOUCHING")
            scrollView.isScrollEnabled = false // disabled scroll
           
            let currentPoint = rotationPanRecognizer.location(in: imageView)
           
            let xOffset = currentPoint.x - touchedPoint.x
            let yOffset = currentPoint.y - touchedPoint.y
             
            selectedLayer?.path = skewShape(corner,xOffset).cgPath
 
            // highlight moving/resizing rect
            let color = UIColor(red: 1, green: 0, blue: 0.3, alpha: 0.4).cgColor
            selectedLayer?.fillColor? = color
            
            touchedPoint = currentPoint
            
        }
         
        
        if gesture.state == UIGestureRecognizer.State.ended {
            
             // if clicked on rotation image cancel scrollView pangesture
            print("***** Touch Ended")
            scrollView.isScrollEnabled = true // enabled scroll
            // update the intial shape with edited edition
            selectedShapesInitial = selectedShape
            if selectedShape != nil {
               
                // updating operation
                var newAllShapes = allShapes.filter {  $0.shape != selectedLayer }
                newAllShapes.append(selectedShape!)
                allShapes = newAllShapes
                
            }
         
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [self] in
                 selectedLayer?.fillColor? = UIColor.clear.cgColor
                selectedLayer = nil
            }
            
            selectedShape = nil
            corner = .noCornersSelected
            touchedPoint = CGPoint.zero
            panStartPoint = CGPoint.zero
          
           
            
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
        let overlayOrigin = CGPoint(x: x+20, y: y+20) // right Corner
  
        overlayImageView.image = UIImage(systemName: "arrow.counterclockwise")
        overlayImageView.frame.origin = overlayOrigin
        overlayImageView.frame.size = CGSize(width: 50, height: 50)
        self.imageView.addSubview(overlayImageView)
      }
    
    func addCornersOverlay(_ layer: CAShapeLayer?) {
        // reset
         
        guard let shape = selectedShapesInitial else { return }
        guard let leftTop = shape.cornersArray.filter({ $0.corner == .leftTop }).first?.point  else { return }
        guard let leftBottom = shape.cornersArray.filter({ $0.corner == .leftBottom }).first?.point else {return }
        guard let rightBottom = shape.cornersArray.filter({ $0.corner == .rightBottom }).first?.point else {return }
        guard let rightTop = shape.cornersArray.filter({ $0.corner == .rightTop }).first?.point else {return }
        
        
        let corners = [leftTop,leftBottom,rightBottom,rightTop]
        
        removeCornerOverlays()
          
        for i in 0...3 {
            
            let imageView = UIImageView(image: UIImage(systemName: "largecircle.fill.circle"))
            imageView.frame.origin = CGPoint(x: corners[i].x-15, y: corners[i].y-15)
            imageView.frame.size = CGSize(width: 30, height: 30)
            self.imageView.addSubview(imageView)
            cornersImageView.append(imageView)
             
        }
          
      }
    
    func moveCornerOverlay(corners:[CGPoint]) {
//        let corners = [leftTopOrigin,leftBottomOrigin,rightBottomOrigin,rightTopOrigin]

        if cornersImageView.count != 0 {
            for i in 0...3 {
                cornersImageView[i].frame.origin = CGPoint(x: corners[i].x-15, y: corners[i].y-15)
                
            }
             
        }
        
    }
    
    func removeCornerOverlays() {
        
        if cornersImageView.count != 0 {
            for i in 0...3 {
                cornersImageView[i].removeFromSuperview()
                
            }
            cornersImageView = [] // reset
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
        
        let leftTopTolerance = CGPoint(x: touchPoint.x-10,y: touchPoint.y-10)
        let leftBottomTolerance = CGPoint(x: touchPoint.x-10,y: touchPoint.y+10)
        let rightBottomTolerance = CGPoint(x: touchPoint.x+10,y: touchPoint.y+10)
        let rightTopTolerance = CGPoint(x: touchPoint.x+10,y: touchPoint.y-10)

        let filteredSubviews = imageView.subviews.filter { subView -> Bool in
            return subView.frame.contains(touchPoint) || subView.frame.contains(leftTopTolerance) || subView.frame.contains(leftBottomTolerance) || subView.frame.contains(rightBottomTolerance) || subView.frame.contains(rightTopTolerance)
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
 
