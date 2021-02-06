//
//  PlanListViewController.swift
//  ImageMap
//
//  Created by Engin KUK on 29.01.2021.
//
 
import UIKit

class PlanListViewController: UIViewController, UITabBarControllerDelegate, UITableViewDataSource, UITableViewDelegate {
 
     static var layoutVC = "LayoutViewController"
       
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    // MARK: - Table view data source
 

    func numberOfSections(in tableView: UITableView) -> Int {
        return dataBase.count
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
        
      
        cell.textLabel?.text = "  " + dataBase[indexPath.section].layoutName + "  Campus"
      
        cell.textLabel?.font = UIFont.systemFont(ofSize: 28)
        cell.textLabel?.textAlignment = .left
        
        cell.layer.cornerRadius = 8
        cell.layer.borderColor = UIColor.gray.cgColor
        cell.layer.borderWidth = 1
        
        cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator

        return cell
    }
 
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let outPut = dataBase[indexPath.section]
        let layoutUrl = outPut.layoutUrl
        let items = outPut.layoutData
        let markerView = MarkerPreviewLayout(input: layoutUrl, markers: items)
        view.addSubview(markerView)
 
     }
}


