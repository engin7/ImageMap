//
//  ViewController.swift
//  ImageMap
//
//  Created by Engin KUK on 11.01.2021.
//

import UIKit

class ViewController: UIViewController, UITextFieldDelegate, UIGestureRecognizerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
 
    
    // TODO: integrate models Arman asked.
    
//    var inputBundle: InputBundle
//
//    public init(url: String, mode: EnumLayoutMapActivity, data: [LayoutMapData]) {
//            self.inputBundle = InputBundle(layoutUrl: url, mode: mode, layoutData: data)
//            super.init(nibName: nil, bundle: nil)
//        }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                              shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
           return true
       }
    
    @IBOutlet weak var controlView: UIView!
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
     
    @IBOutlet weak var pinButton: UIButton!
    @IBAction func pinButtonPressed(_ sender: UIButton) {
        drawingMode = drawMode.dropPin
        sender.setImage(#imageLiteral(resourceName: "pinSelected"), for: UIControl.State.selected)
        pinButton.isSelected = true
        rectButton.isSelected = false
        ellipseButton.isSelected = false
    }
    
    @IBOutlet weak var rectButton: UIButton!
    @IBAction func rectButtonPressed(_ sender: UIButton) {
        drawingMode = drawMode.drawRect
        sender.setImage(#imageLiteral(resourceName: "rectangleShapeSelected"), for: UIControl.State.selected)
        pinButton.isSelected = false
        rectButton.isSelected = true
        ellipseButton.isSelected = false
    }
     
    @IBOutlet weak var ellipseButton: UIButton!
    @IBAction func ellipseButtonPressed(_ sender: UIButton) {
        drawingMode = drawMode.drawEllipse
        sender.setImage(#imageLiteral(resourceName: "ellipseShapeSelected"), for: UIControl.State.selected)
        pinButton.isSelected = false
        rectButton.isSelected = false
        ellipseButton.isSelected = true
    }
    
    var singleTapRecognizer: UITapGestureRecognizer!
    var rotationPanRecognizer : UIPanGestureRecognizer!
    let notificationCenter = NotificationCenter.default
 
    var selectedLayer: CAShapeLayer?
    var pinViewTapped: UIView?
    var handImageView = UIImageView()
    var cornersImageView: [UIImageView] = []
    
    var drawingMode = drawMode.noDrawing
    
    enum drawMode {
        case dropPin
        case drawRect
        case drawEllipse
        case dropPoly
        case noDrawing
    }
    
    let selectedShapeLayer: CAShapeLayer = {
          let shapeLayer = CAShapeLayer()
          shapeLayer.strokeColor = UIColor.black.cgColor
          shapeLayer.fillColor = UIColor.clear.cgColor
          shapeLayer.lineWidth = 4
          shapeLayer.lineDashPattern = [10,5,5,5]
          return shapeLayer
    }()
   
    lazy var trashCanImageView: UIImageView = {
         let imgView = UIImageView(image: #imageLiteral(resourceName: "bin"))
        imgView.frame.size = CGSize(width: 30, height: 30)
        return imgView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateMinZoomScaleForSize(view.bounds.size)

        // Do any additional setup after loading the view.
        controlView.layer.cornerRadius = 22
        controlView.layer.borderColor = UIColor.lightGray.cgColor
        controlView.layer.borderWidth = 0.3
        
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
        case .dropPin:
            if selectedLayer == nil && drawingMode == .dropPin && pinViewTapped == nil  {
                addTag(withLocation: touch, toPhoto: imageView)
            }
            return UIBezierPath()
        case .drawRect:
            return UIBezierPath(rect: frame)
        case .drawEllipse:
            return UIBezierPath(roundedRect: frame, cornerRadius: shapeSize)
        default:
            return UIBezierPath()
        }
    }
    
    private func modifyShape(_ corner: cornerPoint,_ withShift: (x: CGFloat,y: CGFloat) ) -> UIBezierPath {
        
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
        
        var ellipsePath = UIBezierPath()
         
        if drawingMode == .drawEllipse {
             
            guard let leftTop = newCorners.filter({ $0.corner == .leftTop }).first?.point  else { return thePath}
            guard let leftBottom = newCorners.filter({ $0.corner == .leftBottom }).first?.point else {return thePath}
            guard let rightBottom = newCorners.filter({ $0.corner == .rightBottom }).first?.point else {return thePath}
            guard let rightTop = newCorners.filter({ $0.corner == .rightTop }).first?.point else {return thePath}
            
            var lt = CGPoint.zero
            var lb = CGPoint.zero
            var rb = CGPoint.zero
            var rt = CGPoint.zero
             
            switch corner {
            
            case .leftTop:
                lt = leftTop
                lb = CGPoint(x: leftTop.x, y:  leftBottom.y)
                rb = rightBottom
                rt = CGPoint(x: rightTop.x, y: leftTop.y)
            case .leftBottom:
                lt = CGPoint(x: leftBottom.x, y:  leftTop.y)
                lb = leftBottom
                rb = CGPoint(x: rightBottom.x, y: leftBottom.y)
                rt = rightTop
            case .rightBottom:
                lt = leftTop
                lb = CGPoint(x: leftBottom.x, y: rightBottom.y)
                rb = rightBottom
                rt = CGPoint(x: rightBottom.x, y: rightTop.y)
            case .rightTop:
                lt = CGPoint(x: leftTop.x, y:  rightTop.y)
                lb = leftBottom
                rb = CGPoint(x: rightTop.x, y: rightBottom.y)
                rt = rightTop
            case .noCornersSelected:
                lt = leftTop
                lb = leftBottom
                rb = rightBottom
                rt = rightTop
            }
          
            let w = rb.distance(to: lb)
            let h = lb.distance(to: lt)
            
            var frame = CGRect()
            if lt.x < rt.x &&  lt.y < lb.y {
                frame = CGRect(x: lt.x, y: lt.y, width: w, height: h)
            }  else if lt.y > lb.y && lt.x > rt.x {
                frame = CGRect(x: rb.x, y: rb.y, width: w, height: h)
            }  else if lt.x > rt.x {
                frame = CGRect(x: rt.x, y: rt.y, width: w, height: h)
            }  else if lt.y > lb.y {
                frame = CGRect(x: lb.x, y: lb.y, width: w, height: h)
            }
             
            let radii = min(frame.height, frame.width)
            ellipsePath = UIBezierPath(roundedRect: frame, cornerRadius: radii)
            newCorners = []
            
            // save points
            newCorners.append((.leftTop, lt))
            newCorners.append((.leftBottom, lb))
            newCorners.append((.rightBottom, rb))
            newCorners.append((.rightTop, rt))
            
        }
        
        var cornerArray: [CGPoint] = []
        newCorners.forEach{cornerArray.append($0.point)}
        moveCornerOverlay(corners:cornerArray)

        let shapeEdited = shapeInfo(shape: selectedLayer!, cornersArray: newCorners)
        selectedShape = shapeEdited
        
        if drawingMode == .drawEllipse {
            return ellipsePath
        }
        return thePath
    }
    
    // MARK: - Adding Tag

    func addTag(withLocation location: CGPoint, toPhoto photo: UIImageView) {
        let frame = CGRect(x: location.x-20, y: location.y-20, width: 40, height: 40)
        let tempImageView = UIView(frame: frame)
        tempImageView.isUserInteractionEnabled = true
        let pinImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        let tintableImage = #imageLiteral(resourceName: "pin.circle.fill")
        pinImageView.image = tintableImage
        pinImageView.tintColor = .red //will be options
        pinImageView.tag = 4
        tempImageView.addSubview(pinImageView)
        
        let label = UILabel(frame: CGRect(x:40, y: 0, width: 250, height: 30))
        label.textColor = UIColor.red
        label.text = "(\(Double(round(1000*location.x)/1000)), \(Double(round(1000*location.y)/1000)))"
        label.tag = 5
        tempImageView.addSubview(label)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            label.isHidden = true
        }
        tempImageView.tag = 2
        pinViewTapped = tempImageView
        photo.addSubview(tempImageView)
    }
    
    // MARK: - Image Picker
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else { return }

        dismiss(animated: true)
        guard let pin = pinViewTapped  else {return}
        // remove old pin
        pin.subviews.forEach({ if $0.tag == 4 {$0.removeFromSuperview() }})
        pin.tag = 2
        
        let frame =  CGRect(x: 1, y: 20, width: 38, height: 50)
        let cone = UIImageView(frame: frame)
        cone.image = #imageLiteral(resourceName: "arrowtriangle.down.fill")
        cone.tag = 3
        pin.addSubview(cone)
        
        let circleImage = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        circleImage.image = image
        circleImage.layer.masksToBounds = false
        circleImage.layer.cornerRadius = pin.frame.height/2
        circleImage.layer.borderWidth = 2
        circleImage.layer.borderColor = UIColor.systemBlue.cgColor
        circleImage.clipsToBounds = true
        circleImage.tag = 4
        pin.addSubview(circleImage)
        imageView.bringSubviewToFront(pin)
        pinViewTapped = nil
    }
    
    // MARK: - Tapping Tag
 
    @objc func singleTap(gesture: UIRotationGestureRecognizer) {
        let touchPoint = singleTapRecognizer.location(in: imageView)
        var choosingIcon = false
        // add Rect with single tap
         
        // Highlighting rect
        imageView.layer.sublayers?.forEach { layer in
            let layer = layer as? CAShapeLayer
            if let path = layer?.path, path.contains(touchPoint) {
               
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {    [self] in
                     // show hide corner and rotate control
                    cornersImageView.forEach{$0.isHidden = !$0.isHidden}
                    trashCanImageView.isHidden = !trashCanImageView.isHidden
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
        
        //  Detect PIN to drag it !!
        if let pin = touchPoint.getSubViewTouched(imageView: imageView)  {
                     // detect PIN
                    if pin.tag == 2 {
                        pinViewTapped = pin
                        pin.subviews.forEach({ if $0.tag == 5 {$0.isHidden = !$0.isHidden }})
                        // add menu to select image
                            choosingIcon = true
                        let picker = UIImagePickerController()
                            picker.allowsEditing = true
                            picker.delegate = self
                            present(picker, animated: true)
                    }
                }
      
        // No shape selected so add new one
        if selectedLayer == nil && drawingMode != .noDrawing {
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
            
            let layer = shapeInfo(shape: rectLayer, cornersArray: corners)
           
            addAuxiliaryOverlays(layer)
            
            allShapes.append(layer)
             
        }
        
        if !choosingIcon {
            pinViewTapped = nil
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
    var touchedPoint = CGPoint.zero

    @objc func dragging(gesture: UIPanGestureRecognizer) {
     
        if gesture.state == UIGestureRecognizer.State.began {
             
            panStartPoint = rotationPanRecognizer.location(in: imageView)
            // define in which corner we are: (default is no corners)
            let positions = [cornerPoint.leftTop,cornerPoint.leftBottom,cornerPoint.rightBottom,cornerPoint.rightTop]
            if !cornersImageView.isEmpty && cornersImageView.allSatisfy({ $0.isHidden == false }) {
              for i in 0...3 {
                let x = cornersImageView[i].frame.origin.x + 15
                let y = cornersImageView[i].frame.origin.y + 15
                if  CGPoint(x:x, y:y).distance(to: panStartPoint) < 44 {
                    corner = positions[i]
                }
              }
            }
 
                 // TODO: - Refactor this point detection
            imageView.layer.sublayers?.forEach { layer in
                let layer = layer as? CAShapeLayer
                if let path = layer?.path, corner != .noCornersSelected ||  path.contains(panStartPoint) {
                        if (selectedLayer == nil) {
                            selectedLayer = layer!
                            selectedShape =  allShapes.filter {
                                $0.shape == selectedLayer
                            }.first!
                            selectedShapesInitial = selectedShape
                            if let center = getCorners(shape: selectedShape!).centroid()    {
                             if let pin = center.getSubViewTouched(imageView: imageView)  {
                                         // detect PIN
                                        if pin.tag == 2 {
                                              pinViewTapped = pin
                                        }
                                    }
                                }
                            }
                         }
                    }
            if selectedShape == nil  {
            // detect PIN to drag it (no shape condition)
            if let pin = panStartPoint.getSubViewTouched(imageView: imageView)  {
                         // detect PIN
                        if pin.tag == 2 {
                              pinViewTapped = pin
                        }
                    }
               }
       }
                    touchedPoint = panStartPoint // to offset reference

        if gesture.state == UIGestureRecognizer.State.changed && selectedShape != nil || pinViewTapped != nil{
            // we're inside selection
            print("&&&&&&&  TOUCHING")
            print(corner)
            scrollView.isScrollEnabled = false // disabled scroll
           
            let currentPoint = rotationPanRecognizer.location(in: imageView)
            
            let offset = (x: (currentPoint.x - touchedPoint.x), y: (currentPoint.y - touchedPoint.y))
  
             selectedLayer?.path = modifyShape(corner,offset).cgPath
 
            // highlight moving/resizing rect
            let color = UIColor(red: 1, green: 0, blue: 0.3, alpha: 0.4).cgColor
            selectedLayer?.fillColor? = color
            
            if selectedShape == nil {
                pinViewTapped?.frame.origin = CGPoint(x: currentPoint.x-20, y: currentPoint.y-20)
                
            }
            
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
            pinViewTapped = nil
        }
  
    }
    
    func addAuxiliaryOverlays(_ shape: shapeInfo?) {
        // reset
        guard let shape = shape else { return }
        let corners = getCorners(shape: shape)
       
        removeCornerOverlays()
          
        for i in 0...3 {
            let imageView = UIImageView(image: #imageLiteral(resourceName: "largecircle.fill.circle"))
            imageView.frame.origin = CGPoint(x: corners[i].x-15, y: corners[i].y-15)
            imageView.frame.size = CGSize(width: 30, height: 30)
            self.imageView.addSubview(imageView)
            cornersImageView.append(imageView)
        }
        if let centerX = corners.centroid()?.x, let minY = corners.map({ $0.y }).min() {
             trashCanImageView.frame.origin = CGPoint(x: centerX-20, y: minY-40)
             self.imageView.addSubview(trashCanImageView)

          }
      
      }
    
    func moveCornerOverlay(corners:[CGPoint]) {
//        let corners = [leftTopOrigin,leftBottomOrigin,rightBottomOrigin,rightTopOrigin]

            if cornersImageView.count != 0 {
                for i in 0...3 {
                    cornersImageView[i].frame.origin = CGPoint(x: corners[i].x-15, y: corners[i].y-15)
                    
                }
            if let centerX = corners.centroid()?.x, let minY = corners.map({ $0.y }).min() {
                trashCanImageView.frame.origin = CGPoint(x: centerX-20, y: minY-40)
            }
        }
        
    }
    
    func removeCornerOverlays() {
        if cornersImageView.count != 0 {
            for i in 0...3 {
                cornersImageView[i].removeFromSuperview()
                
            }
            trashCanImageView.removeFromSuperview()
            cornersImageView = [] // reset
        }
    }
    
  
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func getCorners(shape: shapeInfo) -> [CGPoint] {
        
        guard let leftTop = shape.cornersArray.filter({ $0.corner == .leftTop }).first?.point  else { return [] }
        guard let leftBottom = shape.cornersArray.filter({ $0.corner == .leftBottom }).first?.point else { return [] }
        guard let rightBottom = shape.cornersArray.filter({ $0.corner == .rightBottom }).first?.point else {return [] }
        guard let rightTop = shape.cornersArray.filter({ $0.corner == .rightTop }).first?.point else {return [] }
        
        
        let corners = [leftTop,leftBottom,rightBottom,rightTop]
        return corners
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
