//
//  MainTableViewController.swift
//  ImageMap
//
//  Created by Engin KUK on 26.01.2021.
//

import UIKit

class MainTableViewController: UIViewController, UITabBarControllerDelegate, UITableViewDataSource, UITableViewDelegate {
 
    static var listVC = "PlanListViewController"
    static var equipmentVC = "EquipmentListViewController"
 
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
            cell.textLabel?.text = "  Buildings & Floor Plans"
         
        default:
            print("sth wrong")
        }
        cell.textLabel?.font = UIFont.systemFont(ofSize: 28)
        cell.textLabel?.textAlignment = .left
        
        cell.layer.cornerRadius = 8
        cell.layer.borderColor = UIColor.gray.cgColor
        cell.layer.borderWidth = 1
        
        cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator

        return cell
    }
 
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
           
        switch indexPath.section {
        
        case 0:
            print("Inspections")
        case 1:
            print("Incidents")
        case 2:
            let vc = self.storyboard?.instantiateViewController(withIdentifier: MainTableViewController.equipmentVC) as! EquipmentListViewController
            self.navigationController?.pushViewController(vc, animated: true)
        case 3:
            let vc = self.storyboard?.instantiateViewController(withIdentifier: MainTableViewController.listVC) as! PlanListViewController
            self.navigationController?.pushViewController(vc, animated: true)
        default:
            print("sth wrong")
        }
        
        
       }
    
    
    

}
 
