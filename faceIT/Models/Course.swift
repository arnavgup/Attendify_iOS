//
//  Course.swift
//  faceIT
//

import Foundation
import Foundation
import ARKit
import SwiftyJSON

class Course {
    
    // Need course ID because all future RoR API calls
    // need to be filtered by the unique class ID
    var courseId: Int
    
    init(courseId: Int) {
        self.courseId = courseId
    }
    
    
    // 1) Get all enrollments, traverse the response and
    //    return only students who are in the same class/courseId
    func getEnrollments() -> [String : [String:Any]] {
        var enrolledStudents = [String : [String:Any]]()
        let enrollments: NSURL = NSURL(string: "https://attendify.herokuapp.com:443/enrollments")!
        let enrollmentsData = NSData(contentsOf: enrollments as URL)!
        let response = try! JSON(data: enrollmentsData as Data)
        for anEnrollment in response {
            if (anEnrollment.1["course_id"].int == self.courseId) {
                let andrew = anEnrollment.1["andrew_id"].string ?? ""
                enrolledStudents[andrew] = ["andrew": andrew]
            }
        }
        return enrolledStudents
    }
    
    // 2) Get all students, and check if their name is in the current
    //    enrolledStudents dictionary; if so, add their student_id, full
    //    name to the dictionary
    func getStudentsInfo(currentDict : [String : [String:Any]]) -> [String : [String:Any]] {
        var enrolledStudents:[String : [String:Any]] = currentDict
        let students: NSURL = NSURL(string: "https://attendify.herokuapp.com:443/students")!
        let studentsData = NSData(contentsOf: students as URL)!
        let allStudents = try! JSON(data: studentsData as Data)
        for student in allStudents {
            let aid = student.1["andrew_id"].string!
            if (enrolledStudents[aid] != nil) {
                let id = student.1["id"].int ?? 0
                let fname = student.1["first_name"].string ?? ""
                let lname = student.1["last_name"].string ?? ""
                let info = ["id":id,"name":fname+" "+lname] as [String : Any]
                enrolledStudents[aid] = info
            }
        }
        return enrolledStudents
    }
    
    // 3) get all photos, and traverse the enrolled Students(currentDict)
    //    dictionary, attempting to get their photo url. If there is no photo,
    //    then a default placeholder image is used
    func getphotos(currentDict : [String : [String:Any]]) -> [String : [String:Any]] {
        var enrolledStudents:[String : [String:Any]] = currentDict
        for (andrew,_) in enrolledStudents {
            let aid = andrew
            let defaultPhoto = "https://upload.wikimedia.org/wikipedia/commons/thumb/9/93/Default_profile_picture_%28male%29_on_Facebook.jpg/600px-Default_profile_picture_%28male%29_on_Facebook.jpg"
            let photos: NSURL = NSURL(string: "https://attendify.herokuapp.com:443/photos?for_andrew_id=\(aid)")!
            let photoData = NSData(contentsOf: photos as URL)!
            let allPhotos = try! JSON(data: photoData as Data)
            var state:Int = 0
            var photoURL:String = ""
            // There should only be 1 photo in allPhotos, but just in case it will traverse
            for photo in allPhotos {
                photoURL = photo.1["photo_url"].string!
                if (photoURL != nil) {
                    state = 1
                    break
                }
            }
            if (state == 0) {
                photoURL = defaultPhoto
            }
            var lastInfo = enrolledStudents[aid]
            lastInfo?["picture"] = photoURL
            enrolledStudents[aid] = lastInfo
        }
        return enrolledStudents
    }
    
    // 4) Finally, we need to get attendance. Attendance is daily, and most
    //    likely there will NOT exist a prior attendance id. If there is,
    //    we will add it to the enrolled student dictionary just as before,
    //    otherwise we will make a POST call and create an attendance;
    //    returning that attendance id
    // 
    func getTodayAttendances(currentDict : [String : [String:Any]]) -> [String : [String:Any]]  {
        var enrolledStudents:[String : [String:Any]] = currentDict
        for (andrew,_) in enrolledStudents {
            let aid = andrew
            let attendance: NSURL = NSURL(string: "https://attendify.herokuapp.com:443/attendances?for_andrew_id=\(aid)&for_class=\(self.courseId)")!
            let attendanceData = NSData(contentsOf: attendance as URL)!
            let allAttendances = try! JSON(data: attendanceData as Data)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            var state = 0
            for attendance in allAttendances {
                // compare dates
                // Convert from string to dates
                let adateString = attendance.1["date"].string!.components(separatedBy: "T")[0]
                let adate = dateFormatter.date(from: adateString) // fix
              if Calendar.current.compare(adate!, to: Date(), toGranularity: .day) == .orderedSame {
                      var lastInfo = enrolledStudents[aid]
                      lastInfo!["attendance_id"] = attendance.1["id"]
                      lastInfo!["status"] = attendance.1["attendance_type"]
                      enrolledStudents[aid] = lastInfo
                      state = 1
                      break
                }
            }
            if (state == 0) {
                var lastInfo = enrolledStudents[aid]
                lastInfo?["attendance_id"] = ""
                lastInfo?["status"] = "Absent"
                enrolledStudents[aid] = lastInfo
            }
        }
        return enrolledStudents
    }
    
    
    // 5) This is the method HomeViewController should call to get a
    //    list of Student objects.
    func getStudents() -> [Student] {
        let enrolledStudents = self.getTodayAttendances(currentDict: getphotos(currentDict: getStudentsInfo(currentDict: getEnrollments())))
      
        let finalResponse = Dictionary(uniqueKeysWithValues:
            enrolledStudents.map { arg in (arg.key,
                                           Student(id: String(describing: arg.value["id"]),
                                           name: arg.value["name"] as! String,
                                           andrew: arg.key,
                                           picture: arg.value["picture"] as! String,
                                           course_id: "1",
                                           status: String(describing: arg.value["status"]),
                                           attendance_id: String(describing: arg.value["attendance_id"]) )) })
        return Array(finalResponse.values)
        
    }
  
  // 6) This is an additional method that will be called in HomeViewController should call
  //    to load up the past 7 days of attendance data
  // TODO: Change this to school days later on, and consult with Arnav to make the scroll
  // wheel to select only on certain days
  func getWeekAttendances() -> [String : [Student]]  {
    var result : [String : [Student]] = [:]
    var enrolledStudents:[String : [String:Any]] = self.getphotos(currentDict: getStudentsInfo(currentDict: getEnrollments()))
    var today = Date()
    var prevDay = Calendar.current.date(byAdding: .day, value: -4, to: Date())!
    today = Calendar.current.date(byAdding: .day, value: +1, to: today)! // This is sketchy; moving day up by one
    // For each day in the range of the starting date (ie. prevDay)
    while prevDay <= today {
      for (andrew,_) in enrolledStudents {
        let aid = andrew
        let attendance: NSURL = NSURL(string: "https://attendify.herokuapp.com:443/attendances?for_andrew_id=\(aid)&for_class=\(self.courseId)")!
        let attendanceData = NSData(contentsOf: attendance as URL)!
        let allAttendances = try! JSON(data: attendanceData as Data)
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = "yyyy-MM-dd"
        var state = 0
        for attendance in allAttendances {
          // compare dates
          // Convert from string to dates
          let adateString = attendance.1["date"].string!.components(separatedBy: "T")[0]
          let adate = dateFormatter.date(from: adateString) // fix
          if Calendar.current.compare(adate!, to: prevDay, toGranularity: .day) == .orderedSame {
            var lastInfo = enrolledStudents[aid]
            lastInfo!["attendance_id"] = attendance.1["id"].string ?? ""
            lastInfo!["status"] = attendance.1["attendance_type"].string ?? "Absent"
            enrolledStudents[aid] = lastInfo
            state = 1
            break
          }
        }
        if (state == 0) {
          var lastInfo = enrolledStudents[aid]
          lastInfo?["attendance_id"] = ""
          lastInfo?["status"] = "Absent"
          enrolledStudents[aid] = lastInfo
        }
        
        var currentDayAttendances = result[dateFormatter.string(from: prevDay)] ?? []
        currentDayAttendances.append(Student(id: String(describing: enrolledStudents[aid]?["name"]),
                                              name: enrolledStudents[aid]?["name"] as! String,
                                              andrew: aid,
                                              picture: enrolledStudents[aid]?["picture"]  as! String,
                                              course_id: String(self.courseId),
                                              status: enrolledStudents[aid]?["status"]  as! String,
                                              attendance_id: enrolledStudents[aid]?["attendance_id"]  as! String))
        result[dateFormatter.string(from: prevDay)] = currentDayAttendances
      }
        prevDay = Calendar.current.date(byAdding: .day, value: +1, to: prevDay)!
    }
    
    return result
  }

    func updateAttendance(enrolledStudents: [Student]) -> () {
        for student in enrolledStudents {
            var status = "Present"
            if(student.status == "Optional(\"Absent\")" || student.status == "Absent")
            {
               status = "Absent"
            }
            var request:URLRequest
            var dict:[String:String]
            let size = student.attendance_id.count - 1
            let lowerBound = student.attendance_id.index(student.attendance_id.startIndex, offsetBy: 9)
            let upperBound = student.attendance_id.index(student.attendance_id.startIndex, offsetBy: size)
            if (student.attendance_id[lowerBound..<upperBound] == "\"\"") {
                let url = URL(string: "https://attendify.herokuapp.com:443/attendances")!
                request = URLRequest(url: url)
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue("application/json", forHTTPHeaderField: "Accept")
                request.httpMethod = "POST"
                dict = ["andrew_id": student.andrew, "date": "\(Date())", "course_id": student.course_id, "attendance_type": status]
            }
            else {
                let u:String! = "https://attendify.herokuapp.com:443/attendances/" + student.attendance_id
                let url = URL(string: "https://attendify.herokuapp.com:443/attendances/" + student.attendance_id[lowerBound..<upperBound])
                request = URLRequest(url: url!)
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue("application/json", forHTTPHeaderField: "Accept")
                request.httpMethod = "PATCH"
                dict = ["id": student.attendance_id,"andrew_id": student.andrew, "date": "\(Date())", "course_id": student.course_id, "attendance_type": status]
            }
            let jsonData = try! JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
            request.httpBody = jsonData
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let _ = data, error == nil else {    // check for fundamental networking error
                    print("error")
                    return
                }
                if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode == 201 { // check for http errors
                    print(response)
                }
            }
            task.resume()
        }
    }
  
    func getCourses() -> [(String,Int)] {
      let attendances: NSURL = NSURL(string: "https://attendify.herokuapp.com:443/courses")!
      let eattendanceData = NSData(contentsOf: attendances as URL)!
      let response = try! JSON(data: eattendanceData as Data)
      var allCourses : [(String,Int)] = [(String,Int)]()
      for course in response {
        allCourses.append((course.1["class_number"].string ?? "",course.1["id"].int ?? 1))
      }
      return allCourses
    }
  
  func getWeeklyAttendance(weekData : [String : [Student]]) -> [String : Int] {
      var weekOfData = weekData // self.getWeekAttendances()
      for day in weekOfData {
        let presentOnly = day.value.filter { $0.status == "Present"}
        weekOfData[day.key] = presentOnly
      }
      // weekOfData should now contain only present students of each day
      // ie. [day1 : [gyao, arnavgup,...]]
      return weekOfData.mapValues {value in
        return value.count}
    }

  func calcToday(weeklyAttendance : [String : Int]) -> String {
      let weeklyAttendance = weeklyAttendance //self.getWeeklyAttendance()
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "yyyy-MM-dd"
      let adate = dateFormatter.string(from: Date()) // fix
      return String(weeklyAttendance[adate] ?? 0)
    }
  
    func calcWeekAverage(weeklyAttendance : [String : Int]) -> String {
      let weeklyAttendance = weeklyAttendance // self.getWeeklyAttendance()
      let avgResult = Double(weeklyAttendance.reduce(0, { x, y in
        x + y.value
      })) / Double(weeklyAttendance.count)
      if (!avgResult.isNaN) {
        return String(avgResult)
      } else {
        return "0"
      }

    }
  
    func calcWeekMax(weeklyAttendance : [String : Int]) -> (String,String) {
      let weeklyAttendance = weeklyAttendance // self.getWeeklyAttendance()
      let maxAttendance = String(weeklyAttendance.reduce(Int.min, { x, y in
        max(x,y.value)}))
      let date = (weeklyAttendance as NSDictionary).allKeys(for: Int(maxAttendance)) as! [String]
      if (date.count != 0) {
        return (date[0], maxAttendance)
      }
      return ("0","0")
    }
  
  
    func calcWeekMin(weeklyAttendance : [String : Int]) -> (String,String) {
      let weeklyAttendance = weeklyAttendance //self.getWeeklyAttendance()
      let minAttendance = String(weeklyAttendance.reduce(Int.max, { x, y in
        min(x,y.value)}))
      let date = (weeklyAttendance as NSDictionary).allKeys(for: Int(minAttendance)) as! [String]
      if (date.count != 0) {
        return (date[0], minAttendance)
      }
      return ("0","0")
    }
  
  
}
