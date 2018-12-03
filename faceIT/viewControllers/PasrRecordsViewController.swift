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
    @IBOutlet weak var markButton:UIButton!
    @IBOutlet weak var returnButton:UIButton!
    
   var attendance: [Student] = todayAttendance
    override func viewDidLoad() {
        super.viewDidLoad()
        self.markButton.layer.cornerRadius = 10
        self.markButton.layer.masksToBounds = true
        self.returnButton.layer.cornerRadius = 10
        self.returnButton.layer.masksToBounds = true
        attendance.sort(by: { $0.andrew > $1.andrew })
        for student in attendance{
            if( student.status == "Optional(Present)"){student.status = "Present"}
            if( student.status == "Optional(Absent)"){student.status = "Absent"}
        }

        // Do any additional setup after loading the view.
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if(attendance[indexPath.row].status == "Present"){
            attendance[indexPath.row].status = "Absent"
        }
        else{
            attendance[indexPath.row].status = "Present"
        }
        self.tableview.reloadData()
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return attendance.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if (attendance[indexPath.row].status == "Present")
        {
            cell.backgroundColor = UIColor(red: 0.8549, green: 0.9686, blue: 0.6863, alpha: 1.0)
        }
        else{
            cell.backgroundColor = UIColor(red: 0.9686, green: 0.7294, blue: 0.6863, alpha: 1.0)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.register(UINib(nibName: "StudentCollectionViewCell", bundle: nil), forCellReuseIdentifier: "studentCell")
        
        let cell = tableview.dequeueReusableCell(withIdentifier: "studentCell", for: indexPath) as! StudentCollectionViewCell
        
        cell.name.text = attendance[indexPath.row].name
        if (attendance[indexPath.row].status == "Present")
        {
            cell.statusPic.image = UIImage(named: "yes.png")
        }
        else{
            cell.statusPic.image = UIImage(named: "no.png")
        }

        do {
            let url = URL(string: (attendance[indexPath.row].picture))!
            let data = try Data(contentsOf: url)
            cell.picture.image = UIImage(data: data)
        }
        catch{
            print(error)
        }
        cell.andrewId.text = attendance[indexPath.row].andrew
        return cell
    }
    
    @IBAction func FilterChanged(_ sender: AnyObject) {
        switch filter.selectedSegmentIndex
        {
        case 0:
            attendance.sort(by: { $0.andrew > $1.andrew })
        case 1:
            attendance.sort(by: { $0.name > $1.name })
        case 2:
            attendance.sort(by: { $0.status > $1.status })
        default:
            break
        }
        self.tableview.reloadData()
    }
    
    @IBAction func datePickerChanged(_ sender: Any) {
        date.datePickerMode = UIDatePickerMode.date
        var dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        var selectedDate = dateFormatter.string(from: date.date)
        print(selectedDate)
        for (day, at) in weekOfAttendance{
            print(at)
            if(day == selectedDate){attendance = at}
//            else{attendance = []}
        }
        print(attendance)
        self.tableview.reloadData()
    }
    
    @IBAction func markAll(_ sender: Any){
        for student in attendance{
            student.status = "Present"
        }
        self.tableview.reloadData()
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
