//
//  UIImageViewExtension.swift
 
import UIKit

let imageCache = NSCache<NSString, UIImage>()
extension UIImageView {
    func loadImageUsingCache(urlString : String) {
        
        guard let url =  URL(string: urlString) else { return}
        
        // check cached image
        if let cachedImage = imageCache.object(forKey: urlString as NSString)  {
            self.image = cachedImage
            return
        }
        
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
                    imageCache.setObject(image, forKey: urlString as NSString)
                    activityIndicator.removeFromSuperview()
                    self.image = image
                    self.setNeedsDisplay()
                }
            }
            
        }).resume()
    }
}
