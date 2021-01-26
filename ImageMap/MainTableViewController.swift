//
//  MainTableViewController.swift
//  ImageMap
//
//  Created by Engin KUK on 26.01.2021.
//

import UIKit

class MainTableViewController: UIViewController, UITabBarControllerDelegate, UITableViewDataSource {
 
    @IBOutlet weak var newEquipmentButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        newEquipmentButton.layer.cornerRadius = 20
    }

    // MARK: - Table view data source
 

    func numberOfSections(in tableView: UITableView) -> Int {
            return 4
        }
    
      func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }
  
      func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      
        let cell: UITableViewCell = {

            guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell")  else {

                    return UITableViewCell(style: .default, reuseIdentifier: "cell")

                    }

                    return cell

                }()
        
        switch indexPath.section {
        
        case 0:
            cell.textLabel?.text = "  Inspections"
        case 1:
            cell.textLabel?.text = "  Incidents"
        case 2:
            cell.textLabel?.text = "  Equipments"
        case 3:
            cell.textLabel?.text = "  Buildings&Floor Plans"
         
        default:
            print("sth wrong")
        }
        cell.textLabel?.font = UIFont.systemFont(ofSize: 28)
        cell.textLabel?.textAlignment = .left
        
        cell.layer.cornerRadius = 8
        cell.layer.borderColor = UIColor.gray.cgColor
        cell.layer.borderWidth = 1
       
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowOpacity = 0.5
        cell.layer.shadowRadius = 2.0
        cell.layer.shadowOffset = CGSize(width: 13.0, height: 12.0)
  
        return cell
    }
 
     

}
