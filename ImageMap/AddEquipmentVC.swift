//
//  AddEquipmentVC.swift
//  ImageMap
//
//  Created by Engin KUK on 27.01.2021.
//

import UIKit

class AddEquipmentViewController: UIViewController {
    
    
    @IBOutlet weak var equipmentCodeTextField: UITextField!
    @IBOutlet weak var equipmentTypeTextField: UITextField!
    
    @IBOutlet weak var addLocationButton: UIButton!
    @IBOutlet weak var addPhotoButton: UIButton!
    
    @IBAction func addLocationButtonTapped(_ sender: Any) {
        
        let addLocationAlert = UIAlertController(title: "Choose Building", message: "", preferredStyle: UIAlertController.Style.actionSheet)
      
        let unfollowAction = UIAlertAction(title: "Choose Building", style: .destructive) { (action: UIAlertAction) in
            // Code to unfollow
        }
        
        let cancelAction = UIAlertAction(title: "CANCEL", style: .cancel, handler: nil)

        addLocationAlert.addAction(unfollowAction)
        addLocationAlert.addAction(cancelAction)
        self.present(addLocationAlert, animated: true, completion: nil)

    }
    
    
    @IBAction func addPhotoButtonTapped(_ sender: Any) {
        // open lib
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
     }
    
    func updateUI() {
        addLocationButton.layer.cornerRadius = 8
        addLocationButton.layer.borderColor = UIColor(white: 0.666667, alpha: 0.15).cgColor
        addLocationButton.layer.borderWidth = 1
        addPhotoButton.layer.cornerRadius = 8
        addPhotoButton.layer.borderColor = UIColor(white: 0.666667, alpha: 0.15).cgColor
        addPhotoButton.layer.borderWidth = 1
    }
    
    
    
}


