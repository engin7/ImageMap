//
//  PlanListViewController.swift
//  ImageMap
//
//  Created by Engin KUK on 29.01.2021.
//
 
import UIKit

class PlanListViewController: UIViewController, UITabBarControllerDelegate, UITableViewDataSource, UITableViewDelegate {
 
    
    override func viewDidLoad() {
        super.viewDidLoad()

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
            cell.textLabel?.text = "  MIT Campus"
        case 1:
            cell.textLabel?.text = "  Harvard Campus"
        case 2:
            cell.textLabel?.text = "  Stanford Campus"
        case 3:
            cell.textLabel?.text = "  Princeton Campus"
         
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

        let vc = self.storyboard?.instantiateViewController(withIdentifier: AddEquipmentViewController.markerVC) as! MarkerViewController

        switch indexPath.section {
            case 0:
                let link = "https://ci.mit.edu/sites/default/files/images/Map-smaller2.png"
                let input = InputBundle(layoutUrl: link, mode: EnumLayoutMapActivity.VIEW, layoutData: nil)
                vc.inputBundle = input
                self.navigationController?.pushViewController(vc, animated: true)
            case 1:
                let link = "https://www.georgeglazer.com/wpmain/wp-content/uploads/2017/02/garfield-harvard-det1.jpg"
                let input = InputBundle(layoutUrl: link, mode: EnumLayoutMapActivity.ADD, layoutData: nil)
                vc.inputBundle = input
                self.navigationController?.pushViewController(vc, animated: true)
            default:
              print("THIS PART WILL BE DYNAMIC LATER")
            }
       }
}



 

 
