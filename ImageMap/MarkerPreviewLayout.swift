  
    //
    //  MarkerPreviewLayout.swift
    //  ImageMarker
    //
    //  Created by Mehbube Arman on 2/4/21.
    //

   import UIKit

    class MarkerPreviewLayout: UIView {
     
        var layoutUrl: String?
        var markers: [LayoutMapData] = []
        private var plotView: UIImageView?
      
        private let imageView: UIImageView = {
            let iv = UIImageView(frame: .zero)
            iv.translatesAutoresizingMaskIntoConstraints = false
            iv.contentMode = .scaleAspectFit
            iv.backgroundColor = .clear
            return iv
        }()
        
        
        init(input: String, markers: [LayoutMapData]) {
                self.layoutUrl = input
                self.markers = markers
                let width = UIScreen.main.bounds.width
                let height = UIScreen.main.bounds.height
            super.init(frame: CGRect(x: 0, y: 0, width: width, height: height))
                configure()
                configurePlot()
            imageView.loadImageUsingCache(urlString: layoutUrl ?? "", completion: { [self] (success) -> Void in
                if success {
                    layoutImage = imageView.image
                    put(markers)
                  }
            })
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
         
        private let loaderView: UIActivityIndicatorView = {
            let indicator = UIActivityIndicatorView(style: .gray)
            indicator.translatesAutoresizingMaskIntoConstraints = false
            indicator.color = .lightGray
            return indicator
        }()

        private var layoutImage: UIImage?

        private var showIndicator: Bool = false {
            didSet {
                DispatchQueue.main.async { [weak self] in
                    if self?.showIndicator == true {
                        self?.loaderView.startAnimating()
                        self?.loaderView.isHidden = false
                    } else {
                        self?.loaderView.stopAnimating()
                        self?.loaderView.isHidden = true
                    }
                }
            }
        }

      
        func put(_ markers: [LayoutMapData]) {
            self.markers.append(contentsOf: markers)
            if let _ = layoutImage {
                plotMarkers()
            }
        }
     
        fileprivate func plotMarkers() {
            if let image = layoutImage, image.size.width >= 100, image.size.height >= 100 {
                let clippedFrame = imageView.contentClippingRect // *This return us image's frame inside imageView
                let size = clippedFrame.size
                UIGraphicsBeginImageContext(size)
                
                guard let context = UIGraphicsGetCurrentContext() else {
                    return
                }
                
                for marker in markers {
                    let markerColor = UIColor(ciColor: .red)
                    switch marker.vector {
                    
                    case let .PIN(pin):
                        
                        let point = imageView.contentClippingPos(point: CGPoint(x: pin.x, y: pin.y))
                        
                        context.saveGState()
                        context.setFillColor(markerColor.cgColor)
                        context.setStrokeColor(markerColor.cgColor)
                        context.setLineWidth(2)
                        
                        context.move(to: point)
                        let lineEnd: CGPoint = .init(x: point.x, y: point.y - 25.0)
                        context.addLine(to: lineEnd)

                        context.addEllipse(in: .init(x: lineEnd.x - 5.0, y: lineEnd.y - 5.0, width: 10.0, height: 10.0))
                        
                        context.drawPath(using: .fillStroke)
                        context.restoreGState()
                        break
                    case let .PATH(points):
                        context.saveGState()

                        context.setFillColor(markerColor.cgColor)
                        context.setAlpha(0.5)

                        for index in 0 ..< points.count {
                            let pin = points[index]
                            let point = pin
                            if index == 0 {
                                context.move(to: point)
                            } else {
                                context.addLine(to: point)
                            }
                        }
                        context.closePath()
                        context.drawPath(using: .fillStroke)
                        context.restoreGState()

                        context.saveGState()
                        context.setFillColor(markerColor.cgColor)
                        for pin in points {
                            let point = pin.addOffset(96, 96)
                            context.addEllipse(in: .init(x: point.x - 9.0, y: point.y - 9.0, width: 18.0, height: 18.0))
                        }
                        context.drawPath(using: .fillStroke)
                        context.restoreGState()

                        break
                    case .ELLIPSE:
                         
                        break
                     }
                }

                if let image = UIGraphicsGetImageFromCurrentImageContext() {
                    DispatchQueue.main.async {
                        self.plotView?.image = image.imageWithBorder(width: 2, color: UIColor.yellow)
                        self.plotView?.setNeedsDisplay()
                        print(self.plotView?.image?.size)

                    }
                }
                    UIGraphicsEndImageContext()
            }
        }
 
        fileprivate func configure() {
            clipsToBounds = true
            self.backgroundColor = .gray
            addSubview(imageView)
            addSubview(loaderView)

            NSLayoutConstraint.activate([
                imageView.leftAnchor.constraint(equalTo: leftAnchor),
                imageView.rightAnchor.constraint(equalTo: rightAnchor),
                imageView.topAnchor.constraint(equalTo: topAnchor),
                imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
                loaderView.centerXAnchor.constraint(equalTo: centerXAnchor),
                loaderView.centerYAnchor.constraint(equalTo: centerYAnchor),
                loaderView.widthAnchor.constraint(equalToConstant: 48),
                loaderView.heightAnchor.constraint(equalToConstant: 48),
            ])
        }
        
        fileprivate func configurePlot() {
           
            self.plotView = UIImageView()
             if let pv = self.plotView {
                addSubview(pv)
                pv.backgroundColor = .clear
                pv.contentMode = .scaleAspectFit
                pv.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    pv.leftAnchor.constraint(equalTo: imageView.leftAnchor),
                    pv.rightAnchor.constraint(equalTo: imageView.rightAnchor),
                    pv.topAnchor.constraint(equalTo: imageView.topAnchor),
                    pv.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
                ])
             }
          }
    }

    extension CGPoint {
        func addOffset(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            return .init(x: self.x + x, y: self.y + y)
        }
    }

