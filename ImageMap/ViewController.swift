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
    
    var singleTapRecognizer: UITapGestureRecognizer!
    var rotationPanRecognizer : UIPanGestureRecognizer!
    let notificationCenter = NotificationCenter.default
 
    var selectedLayer: CAShapeLayer?
    var pinViewTapped = UIView()
    var handImageView = UIImageView()
    var overlayImageView = UIImageView()
    var cornersImageView: [UIImageView] = [] // FIXME:
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
       
        singleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(singleTap))
        scrollView.addGestureRecognizer(singleTapRecognizer)
        
        rotationPanRecognizer = UIPanGestureRecognizer(target: self, action: #selector(dragging))
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
 
    // MARK: - Helper method for drawing Shapes
    
    private func drawShape(touch: CGPoint, mode: drawMode) -> UIBezierPath {
    
        let shapeSize = min(imageView.bounds.width, imageView.bounds.height)/10
        let size = CGSize(width: shapeSize, height: shapeSize)
        let frame = CGRect(origin: touch, size: size)
         
        switch mode {
        case .drawRect:
            return UIBezierPath(rect: frame)
        case .drawPolygon:
            // TODO: make polygon possible
            return UIBezierPath(rect: frame)
        case .drawEllipse:
            return UIBezierPath(roundedRect: frame, cornerRadius: shapeSize)
        default:
            return UIBezierPath()
        }
         
    }
     
    private func skewShape(_ corner: cornerPoint,_ withShift: (x: CGFloat,y: CGFloat) ) -> UIBezierPath {
        
        let thePath = UIBezierPath()
        
        guard let shape = selectedShapesInitial else { return thePath}
        guard let leftTop = shape.cornersArray.filter({ $0.corner == .leftTop }).first?.point  else { return thePath}
        guard let leftBottom = shape.cornersArray.filter({ $0.corner == .leftBottom }).first?.point else {return thePath}
        guard let rightBottom = shape.cornersArray.filter({ $0.corner == .rightBottom }).first?.point else {return thePath}
        guard let rightTop = shape.cornersArray.filter({ $0.corner == .rightTop }).first?.point else {return thePath}
        
        let shiftedLeftTop = CGPoint(x: (leftTop.x + withShift.x), y: (leftTop.y + withShift.y))
        let shiftedLeftBottom = CGPoint(x: (leftBottom.x + withShift.x), y: (leftBottom.y + withShift.y))
        let shiftedRightBottom = CGPoint(x: (rightBottom.x + withShift.x), y: (rightBottom.y + withShift.y))
        let shiftedRightTop = CGPoint(x: (rightTop.x + withShift.x), y: (rightTop.y + withShift.y))
 
        var newCorners: [(corner:cornerPoint,point:CGPoint)] = []
        switch corner {
            
        case .leftTop:
           
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
            thePath.move(to: shiftedLeftTop)
            thePath.addLine(to: shiftedLeftBottom)
            thePath.addLine(to: shiftedRightBottom)
            thePath.addLine(to: shiftedRightTop)
            
            // save points
            newCorners.append((.leftTop, shiftedLeftTop))
            newCorners.append((.leftBottom, shiftedLeftBottom))
            newCorners.append((.rightBottom, shiftedRightBottom))
            newCorners.append((.rightTop, shiftedRightTop))
        }
        
        thePath.close()
    
        var cornerArray: [CGPoint] = []
        newCorners.forEach{cornerArray.append($0.point)}
        moveCornerOverlay(corners:cornerArray)
        overlayImageView.frame.origin = CGPoint(x: cornerArray[2].x+20, y: cornerArray[2].y+20) // right Corner
        guard let point = cornerArray.centroid() else { return thePath}
        selectedShape?.pin.frame.origin = point
        guard let pin = selectedShape?.pin else {return thePath}
        let label = pin.subviews.compactMap { $0 as? UILabel }.first
        label?.text = "(\(Double(round(1000*point.x)/1000)), \(Double(round(1000*point.y)/1000)))"
        
        let shapeEdited = shapeInfo(pin: pin, shape: selectedLayer!, cornersArray: newCorners)
        selectedShape = shapeEdited
        
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
        pinViewTapped = tempImageView
        photo.addSubview(tempImageView)
    }
    
    // MARK: - Tapping Tag

    @objc func singleTap(gesture: UIRotationGestureRecognizer) {
        let touchPoint = singleTapRecognizer.location(in: imageView)
       
        // add Rect with single tap
         
        // Highlighting rect
        imageView.layer.sublayers?.forEach { layer in
            let layer = layer as? CAShapeLayer
            if let path = layer?.path, path.contains(touchPoint) {
               
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {    [self] in
                     // show hide corner and rotate control
                    overlayImageView.isHidden = !overlayImageView.isHidden
                }
                 if (selectedLayer == nil) {
                    selectedLayer = layer
                    selectedShape =  allShapes.filter {
                        $0.shape == selectedLayer!
                    }.first!
                    selectedShapesInitial = selectedShape
                    var corners: [CGPoint] = []
                    selectedShapesInitial?.cornersArray.forEach{corners.append($0.point)}
                    moveCornerOverlay(corners:corners)
                }
                  
            }
        }
 
             // hide label, highlight pin etc
        if let pin = selectedShape?.pin {
            pin.subviews.forEach({ $0.isHidden = !$0.isHidden })
            if pin.tintColor == .red {
                pin.tintColor = .systemBlue
            } else {
                pin.tintColor = .red
            }
        }
        
        // just add pin
        if selectedLayer == nil && drawingMode == .noShape  {
            addTag(withLocation: touchPoint, toPhoto: imageView)
        }
        
        // No shape selected so add new one
        if selectedLayer == nil && drawingMode != .noShape {
            //add shape
            // draw rectangle, ellipse etc according to selection
            imageView.layer.addSublayer(selectedShapeLayer)
            let path = drawShape(touch: touchPoint, mode: drawingMode)
            selectedShapeLayer.path = path.cgPath
            
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
            
            var cornerPoints: [CGPoint] = []
            corners.forEach{cornerPoints.append($0.point)}
            
            guard let center = cornerPoints.centroid() else { return }
            
            addTag(withLocation: center, toPhoto: imageView)

            let layer = shapeInfo(pin: pinViewTapped, shape: rectLayer, cornersArray: corners)
            
            addRotationOverlay(layer)
            addCornersOverlay(layer)
            
            allShapes.append(layer)
             
        }
        
        selectedLayer = nil
        selectedShapeLayer.path = nil

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
        var pin: UIView
        
        init(pin: UIView, shape: CAShapeLayer, cornersArray: [(cornerPoint,CGPoint)] ) {
            self.pin = pin
            self.shape = shape
            self.cornersArray = cornersArray
           }
    }
    
    var selectedShape: shapeInfo?
    var selectedShapesInitial: shapeInfo?
    var allShapes: [shapeInfo] = []
    var corner = cornerPoint()
    var panStartPoint = CGPoint.zero
    var touchedPoint = CGPoint.zero

    
    @objc func dragging(gesture: UIPanGestureRecognizer) {
     
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
            
            if let subviewTouched =  panStartPoint.getSubViewTouched(imageView: imageView) {

                scrollView.isScrollEnabled = false // disabled scroll

                if subviewTouched == overlayImageView {
                    // rotating button
                    print("INSIDE rot overlay")
                    corner = .noCornersSelected
                } else {
                    print("INSIDE CORNERS")
                    // corners or pin
                    if cornersImageView.count > 0 {
                        if subviewTouched == cornersImageView[0] {
                            corner = .leftTop
                        } else if subviewTouched == cornersImageView[1] {
                            corner = .leftBottom
                        } else if subviewTouched == cornersImageView[2] {
                            corner = .rightBottom
                        } else if subviewTouched == cornersImageView[3] {
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
           
            let offset = (x: (currentPoint.x - touchedPoint.x), y: (currentPoint.y - touchedPoint.y))
  
             selectedLayer?.path = skewShape(corner,offset).cgPath
 
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
     
    func addRotationOverlay(_ shape: shapeInfo?) {
 
       guard let shape = shape else { return }
       guard let rightBottom = shape.cornersArray.filter({ $0.corner == .rightBottom }).first?.point else {return }
        let overlayOrigin = CGPoint(x: rightBottom.x+20, y: rightBottom.y+20) // right Corner
  
        overlayImageView.image = UIImage(systemName: "arrow.counterclockwise")
        overlayImageView.frame.origin = overlayOrigin
        overlayImageView.frame.size = CGSize(width: 50, height: 50)
        self.imageView.addSubview(overlayImageView)
      }
    
    func addCornersOverlay(_ shape: shapeInfo?) {
        // reset
         
        guard let shape = shape else { return }
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
