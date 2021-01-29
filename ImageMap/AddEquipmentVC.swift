//
//  AddEquipmentVC.swift
//  ImageMap
//
//  Created by Engin KUK on 27.01.2021.
//

import UIKit

class AddEquipmentViewController: UIViewController {
    
    static var markerVC = "MarkerViewController"
    
    @IBOutlet weak var equipmentCodeTextField: UITextField!
    @IBOutlet weak var equipmentTypeTextField: UITextField!
    
    @IBOutlet weak var addLocationButton: UIButton!
    @IBOutlet weak var addPhotoButton: UIButton!
    
    @IBAction func addLocationButtonTapped(_ sender: Any) {
        
        let addLocationAlert = UIAlertController(title: "Choose Building", message: "", preferredStyle: UIAlertController.Style.actionSheet)
      
        let vc = self.storyboard?.instantiateViewController(withIdentifier: AddEquipmentViewController.markerVC) as! MarkerViewController
        vc.recordId = equipmentCodeTextField?.text ?? ""
        vc.recordTypeId = equipmentTypeTextField?.text ?? ""
        
        let addMarkAction0 = UIAlertAction(title: "MIT Campus", style: .destructive) { [self] (action: UIAlertAction) in
            let link = "https://ci.mit.edu/sites/default/files/images/Map-smaller2.png"
            let input = InputBundle(layoutUrl: link, mode: EnumLayoutMapActivity.ADD, layoutData: nil)
            vc.inputBundle = input
            self.navigationController?.pushViewController(vc, animated: true)
        }
        
        let addMarkAction1 = UIAlertAction(title: "Harvard Campus", style: .destructive) {  (action: UIAlertAction) in
            let link = "https://www.georgeglazer.com/wpmain/wp-content/uploads/2017/02/garfield-harvard-det1.jpg"
            let input = InputBundle(layoutUrl: link, mode: EnumLayoutMapActivity.ADD, layoutData: nil)
            vc.inputBundle = input
            self.navigationController?.pushViewController(vc, animated: true)
        }        
        let cancelAction = UIAlertAction(title: "CANCEL", style: .cancel, handler: nil)
        addLocationAlert.addAction(addMarkAction0)
        addLocationAlert.addAction(addMarkAction1)
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


