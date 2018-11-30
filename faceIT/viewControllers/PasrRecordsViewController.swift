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
    
//   var attendance: [Student] = Course(courseId: 1).getStudents()
    override func viewDidLoad() {
        super.viewDidLoad()
        todayAttendance.sort(by: { $0.andrew > $1.andrew })
        for student in todayAttendance{
            if( student.status == "Optional(Present)"){student.status = "Present"}
            if( student.status == "Optional(Absent)"){student.status = "Absent"}
        }

        // Do any additional setup after loading the view.
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if(todayAttendance[indexPath.row].status == "Present"){
            todayAttendance[indexPath.row].status = "Absent"
        }
        else{
            todayAttendance[indexPath.row].status = "Present"
        }
        self.tableview.reloadData()
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todayAttendance.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if (todayAttendance[indexPath.row].status == "Present")
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
        
        cell.name.text = todayAttendance[indexPath.row].name
        
        do {
            let url = URL(string: (todayAttendance[indexPath.row].picture))!
            let data = try Data(contentsOf: url)
            cell.picture.image = UIImage(data: data)
        }
        catch{
            print(error)
        }
        cell.andrewId.text = todayAttendance[indexPath.row].andrew
        return cell
    }
    
    @IBAction func FilterChanged(_ sender: AnyObject) {
        switch filter.selectedSegmentIndex
        {
        case 0:
            todayAttendance.sort(by: { $0.andrew > $1.andrew })
        case 1:
            todayAttendance.sort(by: { $0.name > $1.name })
        case 2:
            todayAttendance.sort(by: { $0.status > $1.status })
        default:
            break
        }
        self.tableview.reloadData()
    }
    
    @IBAction func datePickerChanged(_ sender: Any) {
        date.datePickerMode = UIDatePickerMode.date
        var dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yyyy"
        var selectedDate = dateFormatter.string(from: date.date)
        print(selectedDate)
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
