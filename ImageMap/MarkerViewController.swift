

//
//  MarkerViewController.swift
//  ImageMap
//
//  Created by Engin KUK on 11.01.2021.
//

import UIKit

class MarkerViewController: UIViewController, UITextFieldDelegate, UIGestureRecognizerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
 
    
// TODO: - integrate models.

    var inputBundle: InputBundle?
    var vectorType: LayoutVector?
    var vectorData: VectorMetaData?
    var recordId = ""
    var recordTypeId = ""
    @IBAction func saveButtonPressed(_ sender: Any) {
        
        if vectorType != nil, vectorData != nil {
            let data = LayoutMapData(vector: vectorType!, metaData: vectorData!)
            // SAVE DATA LOGIC HERE
        }
       
        print("NOTHING TO SAVE HERE...")
         
    }
     
    @IBOutlet weak var controlView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewTrailingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var pinButton: UIButton!
    
    @IBAction func pinButtonPressed(_ sender: UIButton) {
        if drawingMode != drawMode.dropPin {
            drawingMode = drawMode.dropPin
            sender.setImage(#imageLiteral(resourceName: "pinSelected"), for: UIControl.State.selected)
            pinButton.isSelected = true
            rectButton.isSelected = false
            ellipseButton.isSelected = false
            resetUI()
        }
    }
    
    @IBOutlet weak var rectButton: UIButton!
    @IBAction func rectButtonPressed(_ sender: UIButton) {
        if drawingMode != drawMode.drawRect {
        drawingMode = drawMode.drawRect
        sender.setImage(#imageLiteral(resourceName: "rectangleShapeSelected"), for: UIControl.State.selected)
        pinButton.isSelected = false
        rectButton.isSelected = true
        ellipseButton.isSelected = false
        resetUI()
        }
    }
     
    @IBOutlet weak var ellipseButton: UIButton!
    @IBAction func ellipseButtonPressed(_ sender: UIButton) {
        if drawingMode != drawMode.drawEllipse {
        drawingMode = drawMode.drawEllipse
        sender.setImage(#imageLiteral(resourceName: "ellipseShapeSelected"), for: UIControl.State.selected)
        pinButton.isSelected = false
        rectButton.isSelected = false
        ellipseButton.isSelected = true
        resetUI()
        }
    }
    
    var singleTapRecognizer: UITapGestureRecognizer!
    var rotationPanRecognizer : UIPanGestureRecognizer!
    let notificationCenter = NotificationCenter.default
 
    var currentLayer: CAShapeLayer?
    var selectedLayer: CAShapeLayer?
    var pinViewTapped: UIView?
    var pinViewAdded: UIView?
    var pinImage: UIView?
    var handImageView = UIImageView()
    var cornersImageView: [UIImageView] = []
    var labelDetail = UILabel()
    
    lazy var detailView : UIView = {
        let width = UIScreen.main.bounds.width
        let height = UIScreen.main.bounds.height
        let detail = UIView(frame: CGRect(x: 0, y: height, width: width, height: 300))
        detail.backgroundColor = .white
        detail.layer.cornerRadius = 8
        detail.layer.borderColor = UIColor.lightGray.cgColor
        detail.layer.borderWidth = 0.5
        
        let label = UILabel(frame: CGRect(x: 20, y: 20, width: width-40, height: 40))
        label.text = "Record Details"
        label.textAlignment = .center
        detail.addSubview(label)
        
        labelDetail = UILabel(frame: CGRect(x: 20, y: 40, width: width-40, height: 240))
        labelDetail.font = UIFont(name: "Helvetica Neue", size: 14)
        labelDetail.textAlignment = .center
        labelDetail.lineBreakMode = NSLineBreakMode.byWordWrapping
        labelDetail.numberOfLines = 12
        detail.addSubview(labelDetail)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        swipeDown.direction = .down
        detail.addGestureRecognizer(swipeDown)
        self.view.addSubview(detail)
        
    // add scroll down gesture
    return detail
    }()
      
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                              shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
           return true
       }
    
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
   
    lazy var deleteButton: UIButton = {
        let button = UIButton()
        button.frame.size = CGSize(width: 30, height: 30)
        button.setImage(#imageLiteral(resourceName: "bin"), for: UIControl.State.normal)
        button.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        return button
    }()
    
    @objc func deleteButtonTapped() {
        resetUI()
    }
    
    func resetUI() {
        pinViewAdded?.removeFromSuperview()
        selectedLayer?.removeFromSuperlayer()
        removeAuxiliaryOverlays()
        addedObject = nil
        pinViewAdded = nil
    }
    
    
    @IBAction func magentaTapped(_ sender: Any) {
        drawingColor = drawColor.magenta
        pinImage?.tintColor = drawingColor.associatedColor
        selectedLayer?.fillColor? = drawingColor.associatedColor.cgColor
    }
    
    @IBAction func yellowTapped(_ sender: Any) {
        drawingColor = drawColor.yellow
        pinImage?.tintColor = drawingColor.associatedColor
        selectedLayer?.fillColor? = drawingColor.associatedColor.cgColor
    }
    
    @IBAction func cyanTapped(_ sender: Any) {
        drawingColor = drawColor.cyan
        pinImage?.tintColor = drawingColor.associatedColor
        selectedLayer?.fillColor? = drawingColor.associatedColor.cgColor
    }
    
    @IBAction func greenTapped(_ sender: Any) {
        drawingColor = drawColor.green
        pinImage?.tintColor = drawingColor.associatedColor
        selectedLayer?.fillColor? = drawingColor.associatedColor.cgColor
    }
    
    @IBAction func orangeTapped(_ sender: Any) {
        drawingColor = drawColor.orange
        pinImage?.tintColor = drawingColor.associatedColor
        selectedLayer?.fillColor? = drawingColor.associatedColor.cgColor
    }
    
    @IBAction func redTapped(_ sender: Any) {
        drawingColor = drawColor.red
        pinImage?.tintColor = drawingColor.associatedColor
        selectedLayer?.fillColor? = drawingColor.associatedColor.cgColor
    }
    
    @IBAction func blueTapped(_ sender: Any) {
        drawingColor = drawColor.blue
        pinImage?.tintColor = drawingColor.associatedColor
        selectedLayer?.fillColor? = drawingColor.associatedColor.cgColor
    }
    
    var drawingColor = drawColor.blue
    enum drawColor {
        case magenta
        case yellow
        case cyan
        case green
        case orange
        case red
        case blue
        
            var associatedColor: UIColor {
                  switch self {
                    case .magenta: return UIColor.magenta.withAlphaComponent(0.25)
                    case .yellow: return  UIColor.yellow.withAlphaComponent(0.25)
                    case .cyan: return  UIColor.cyan.withAlphaComponent(0.25)
                    case .green: return UIColor.green.withAlphaComponent(0.25)
                    case .orange: return  UIColor.orange.withAlphaComponent(0.25)
                    case .red: return  UIColor.red.withAlphaComponent(0.25)
                    case .blue: return  UIColor.blue.withAlphaComponent(0.25)
                  }
              }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateMinZoomScaleForSize(view.bounds.size)
        
        // Download image from URL
        imageView.loadImageUsingCache(urlString: inputBundle?.layoutUrl ?? "")
        
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
            currentLayer?.anchorPoint = CGPoint(x: 0, y: 0)
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
        moveAuxiliaryOverlays(corners:cornerArray)
        
        if let layer = currentLayer {
            let shapeEdited = shapeInfo(shape: layer, cornersArray: newCorners)
            addedObject = shapeEdited
        }
        
        
        switch drawingMode {
        
        case .drawRect:
                vectorType = .PATH(points: cornerArray)
            if let color = selectedLayer?.fillColor  {
                 let colorInfo = UIColor(cgColor: color).toRGBAString()
                vectorData = VectorMetaData(color: colorInfo, iconUrl: "PUT Rect URL HERE", recordId: recordId, recordTypeId: recordTypeId)
            }
           
        case .drawEllipse:
                let shapeSize = min(imageView.bounds.width, imageView.bounds.height)/10
                vectorType = .ELLIPSE(points: cornerArray, cornerRadius: shapeSize)
            if let color = selectedLayer?.fillColor  {
                 let colorInfo = UIColor(cgColor: color).toRGBAString()
                vectorData = VectorMetaData(color: colorInfo, iconUrl: "PUT Ellipse URL HERE", recordId: recordId, recordTypeId: recordTypeId)
            }

        default:
               print("Sth is wrong!")
        }
        
        
        if drawingMode == .drawEllipse {
            return ellipsePath
        }
        return thePath
    }
    
    // MARK: - Adding Tag

    func addTag(withLocation location: CGPoint, toPhoto photo: UIImageView) {
        
        deleteButton.frame.origin = CGPoint(x: location.x-15, y: location.y-50)
        imageView.addSubview(deleteButton)
        
        let frame = CGRect(x: location.x-20, y: location.y-20, width: 40, height: 40)
        let pinViewTapped = UIView(frame: frame)
        pinViewTapped.isUserInteractionEnabled = true
        let pinImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        let originalImage = #imageLiteral(resourceName: "pin.circle.fill")
        let templateImage = originalImage.withRenderingMode(.alwaysTemplate)
        pinImageView.image = templateImage
        pinImageView.tintColor = drawingColor.associatedColor
        pinImageView.tag = 4
        pinViewTapped.addSubview(pinImageView)
        pinImage = pinImageView
        
        let label = UILabel(frame: CGRect(x:40, y: 0, width: 250, height: 30))
        label.textColor = UIColor.red
        label.text = "(\(Double(round(1000*location.x)/1000)), \(Double(round(1000*location.y)/1000)))"
        label.tag = 5
        pinViewTapped.addSubview(label)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            label.isHidden = true
        }
        pinViewTapped.tag = 2
        photo.addSubview(pinViewTapped)
        pinViewAdded = pinViewTapped
        // recordId & recordTypeId will come from previous VC textfield.
        vectorType = .PIN(point: location)
        if let color = pinViewTapped.tintColor  {
             let colorInfo = color.toRGBAString()
            vectorData = VectorMetaData(color: colorInfo, iconUrl: "PUT PIN URL HERE", recordId: recordId, recordTypeId: recordTypeId)
        }
 
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
    
    
    // MARK: - animate detail view
    func showDetailView() {
          UIView.animate(withDuration: 1, delay: 0, options: [.curveEaseOut],
                         animations: { [self] in
                            detailView.center.y = self.view.bounds.height - 150
                            self.view.layoutIfNeeded()
        }, completion: nil)
      
        labelDetail.text = (vectorType.debugDescription ?? "No Type info") + "\n\n\n" + (vectorData.debugDescription ?? "information not available.")
         
    }

    @objc func handleGesture() {
        UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseOut],
                       animations: { [self] in
                          detailView.center.y = self.view.bounds.height + 150
                          self.view.layoutIfNeeded()
      }, completion: nil)
    }
    
    
    // MARK: - Tapping Tag
 
    @objc func singleTap(gesture: UIRotationGestureRecognizer) {
        let touchPoint = singleTapRecognizer.location(in: imageView)
       
        
        // Highlighting rect
        imageView.layer.sublayers?.forEach { layer in
            let layer = layer as? CAShapeLayer
            if let path = layer?.path, path.contains(touchPoint) {
                
                 if (currentLayer == nil) {
                    currentLayer = layer
                    selectedShapesInitial = addedObject
                    var corners: [CGPoint] = []
                    selectedShapesInitial?.cornersArray.forEach{corners.append($0.point)}
                    moveAuxiliaryOverlays(corners:corners)
                    showDetailView()
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
                        let picker = UIImagePickerController()
                            picker.allowsEditing = true
                            picker.delegate = self
                            present(picker, animated: true)
                    }
                }
      
       // add new pin if there isnt
            if currentLayer == nil && drawingMode == .dropPin && pinViewAdded == nil  {
                addTag(withLocation: touchPoint, toPhoto: imageView)
             }
           
        // No shape selected or added so add new one
        if currentLayer == nil && drawingMode != .noDrawing && addedObject == nil && drawingMode != .dropPin {
            //add shape
            // draw rectangle, ellipse etc according to selection
            imageView.layer.addSublayer(selectedShapeLayer)
            let path = drawShape(touch: touchPoint, mode: drawingMode)
            selectedShapeLayer.path = path.cgPath
            
            let rectLayer = CAShapeLayer()
            rectLayer.strokeColor = UIColor.black.cgColor
            rectLayer.lineWidth = 4
            rectLayer.path = selectedShapeLayer.path
            rectLayer.fillColor? = drawingColor.associatedColor.cgColor

            imageView.layer.addSublayer(rectLayer)
            selectedLayer = rectLayer

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
            
            addedObject = shapeInfo(shape: rectLayer, cornersArray: corners)
            addAuxiliaryOverlays(addedObject)
            
            switch drawingMode {
            
            case .drawRect:
                    vectorType = .PATH(points: cornerPoints)
                if let color = selectedLayer?.fillColor  {
                     let colorInfo = UIColor(cgColor: color).toRGBAString()
                    vectorData = VectorMetaData(color: colorInfo, iconUrl: "PUT Rect URL HERE", recordId: recordId, recordTypeId: recordTypeId)
                }
            case .drawEllipse:
                    let shapeSize = min(imageView.bounds.width, imageView.bounds.height)/10
                    vectorType = .ELLIPSE(points: cornerPoints, cornerRadius: shapeSize)
                if let color = selectedLayer?.fillColor  {
                     let colorInfo = UIColor(cgColor: color).toRGBAString()
                    vectorData = VectorMetaData(color: colorInfo, iconUrl: "PUT Ellipse URL HERE", recordId: recordId, recordTypeId: recordTypeId)
                }
            default:
                   print("Sth is wrong!")
            }
             
        }
        
        currentLayer = nil
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
    struct shapeInfo: Equatable {
        
        static func == (lhs: MarkerViewController.shapeInfo, rhs: MarkerViewController.shapeInfo) -> Bool {
            true
        }
        
        var shape: CAShapeLayer
        var cornersArray : [(corner: cornerPoint,point: CGPoint)]
 
        init(shape: CAShapeLayer, cornersArray: [(cornerPoint,CGPoint)] ) {
            self.shape = shape
            self.cornersArray = cornersArray
           }
    }
    
    var addedObject: shapeInfo?
    var selectedShapesInitial: shapeInfo?
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
                if let path = layer?.path, corner != .noCornersSelected ||  path.contains(panStartPoint)  {
                        if (currentLayer == nil) {
                            currentLayer = layer!
                            selectedShapesInitial = addedObject
                          }
                         }
                    }
            
            // detect PIN to drag it (no shape condition)
            if let pin = panStartPoint.getSubViewTouched(imageView: imageView)  {
                         // detect PIN
                        if pin.tag == 2 {
                              pinViewTapped = pin
                        }
                    }
            
       }
                    touchedPoint = panStartPoint // to offset reference

        if gesture.state == UIGestureRecognizer.State.changed && selectedShapesInitial != nil || pinViewTapped != nil{
            // we're inside selection
            print("&&&&&&&  TOUCHING")
            print(corner)
            scrollView.isScrollEnabled = false // disabled scroll
           
            let currentPoint = rotationPanRecognizer.location(in: imageView)
            
            let offset = (x: (currentPoint.x - touchedPoint.x), y: (currentPoint.y - touchedPoint.y))
  
            currentLayer?.path = modifyShape(corner,offset).cgPath
             
            if pinViewTapped != nil {
                pinViewTapped?.frame.origin = CGPoint(x: currentPoint.x-20, y: currentPoint.y-20)
                deleteButton.frame.origin = CGPoint(x: currentPoint.x-15, y: currentPoint.y-50)
            }
            
            touchedPoint = currentPoint
            
        }
          
        if gesture.state == UIGestureRecognizer.State.ended {
            
             // if clicked on rotation image cancel scrollView pangesture
            print("***** Touch Ended")
            scrollView.isScrollEnabled = true // enabled scroll
            // update the intial shape with edited edition
            selectedShapesInitial = addedObject
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [self] in
                selectedLayer = currentLayer
                currentLayer = nil
            }
            
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
       
        removeAuxiliaryOverlays()
          
        for i in 0...3 {
            let imageView = UIImageView(image: #imageLiteral(resourceName: "largecircle.fill.circle"))
            imageView.frame.origin = CGPoint(x: corners[i].x-15, y: corners[i].y-15)
            imageView.frame.size = CGSize(width: 30, height: 30)
            self.imageView.addSubview(imageView)
            cornersImageView.append(imageView)
        }
        if let centerX = corners.centroid()?.x, let minY = corners.map({ $0.y }).min() {
             deleteButton.frame.origin = CGPoint(x: centerX-20, y: minY-50)
             self.imageView.addSubview(deleteButton)

          }
      
      }
    
    func moveAuxiliaryOverlays(corners:[CGPoint]) {
//        let corners = [leftTopOrigin,leftBottomOrigin,rightBottomOrigin,rightTopOrigin]

            if cornersImageView.count != 0 {
                for i in 0...3 {
                    cornersImageView[i].frame.origin = CGPoint(x: corners[i].x-15, y: corners[i].y-15)
                    
                }
            if let centerX = corners.centroid()?.x, let minY = corners.map({ $0.y }).min() {
                deleteButton.frame.origin = CGPoint(x: centerX-20, y: minY-50)
            }
        }
        
    }
    
    func removeAuxiliaryOverlays() {
        if cornersImageView.count != 0 {
            for i in 0...3 {
                cornersImageView[i].removeFromSuperview()
            }
            cornersImageView = [] // reset
        }
        deleteButton.removeFromSuperview()
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

extension MarkerViewController: UIScrollViewDelegate {
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
