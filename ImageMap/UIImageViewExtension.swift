//
//  UIImageViewExtension.swift
 
import UIKit

let imageCache = NSCache<NSString, UIImage>()
typealias CompletionHandler = ( _ success:Bool) -> Void

extension UIImageView {
    
 
    func loadImageUsingCache(urlString : String, completion: @escaping CompletionHandler) {
        
        guard let url =  URL(string: urlString) else { return}
        
      
        
        let activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView.init()
        addSubview(activityIndicator)
        activityIndicator.startAnimating()
        activityIndicator.center = self.center
        
        // if not, download image from url
        URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
            if error != nil {
                print(error!)
                DispatchQueue.main.async {
                    self.image =  #imageLiteral(resourceName: "noImage")
                    self.contentMode = .scaleAspectFit
                    activityIndicator.removeFromSuperview()
                }
                return
            }
            
            DispatchQueue.main.async {
                if let image = UIImage(data: data!) {
                    activityIndicator.removeFromSuperview()
                    self.image = image
                    self.setNeedsDisplay()
                    completion(true)
                }
            }
            
        }).resume()
    }
}


extension UIImageView {
    func contentClippingPos(point: CGPoint) -> CGPoint {
        guard let image = image else { return .zero }
        guard contentMode == .scaleAspectFit else { return .zero }
        guard image.size.width > 0 && image.size.height > 0 else { return .zero }

        let scale: CGFloat
        if image.size.width > image.size.height {
            scale = bounds.width / image.size.width
        } else {
            scale = bounds.height / image.size.height
        }
        let x =  (point.x * scale)
        let y =  (point.y * scale)
        // here i removed (bounds.width - size.width) / 2.0 since we're operating directly on image size, we dont need origin differences.
        return CGPoint(x: x, y: y)
    }
    
}

extension UIImageView {
    var contentClippingRect: CGRect {
        guard let image = image else { return bounds }
        guard contentMode == .scaleAspectFit else { return bounds }
        guard image.size.width > 0 && image.size.height > 0 else { return bounds }

        let scale: CGFloat
        if image.size.width > image.size.height {
            scale = bounds.width / image.size.width
        } else {
            scale = bounds.height / image.size.height
        }

        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        
        let x = (bounds.width - size.width) / 2.0
        let y = (bounds.height - size.height) / 2.0
        
        return CGRect(x: x, y: y, width: size.width, height: size.height)
    }
}


extension UIImage {
    func imageWithBorder(width: CGFloat, color: UIColor) -> UIImage? {
        let imageView = UIImageView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: size))
        imageView.image = self
        imageView.layer.borderWidth = width
        imageView.layer.borderColor = color.cgColor
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        imageView.layer.render(in: context)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
}
