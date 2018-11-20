//
//  PasrRecordsViewController.swift
//  faceIT
//
//  Created by Arnav Gupta on 11/9/18.
//  Copyright © 2018 NovaTec GmbH. All rights reserved.
//

import UIKit

class PasrRecordsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var tableview: UITableView!
    @IBOutlet var filter: UISegmentedControl!
    @IBOutlet var date: UIDatePicker!
    
   var attenance: [Student] = Course(courseId: 1).getStudents()
    override func viewDidLoad() {
        super.viewDidLoad()
        for student in attenance{
            if( student.status == "Optional(Present)"){student.status = "Present"}
            if( student.status == "Optional(Absent)"){student.status = "Absent"}
        }

        // Do any additional setup after loading the view.
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if(attenance[indexPath.row].status == "Present"){
            attenance[indexPath.row].status = "Absent"
        }
        else{
            attenance[indexPath.row].status = "Present"
        }
        self.tableview.reloadData()
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return attenance.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        print(attenance[indexPath.row].andrew)
        if (attenance[indexPath.row].status == "Present")
        {
            cell.backgroundColor = UIColor(red: 0.0078, green: 0.4078, blue: 0.1333, alpha: 1.0)
        }
        else{
            cell.backgroundColor = UIColor(red: 0.7176, green: 0.0353, blue: 0.0118, alpha: 1.0)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.register(UINib(nibName: "StudentCollectionViewCell", bundle: nil), forCellReuseIdentifier: "studentCell")
        
        let cell = tableview.dequeueReusableCell(withIdentifier: "studentCell", for: indexPath) as! StudentCollectionViewCell
        
        cell.name.text = attenance[indexPath.row].name
        
        do {
            let url = URL(string: (attenance[indexPath.row].picture))!
            let data = try Data(contentsOf: url)
            cell.picture.image = UIImage(data: data)
        }
        catch{
            print(error)
        }
        cell.andrewId.text = attenance[indexPath.row].andrew
        return cell
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
