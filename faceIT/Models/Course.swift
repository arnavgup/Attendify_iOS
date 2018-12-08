//
//  Course.swift
//  faceIT
//  Updated by George Yao
//  Last updated: December 6th, 2018

import Foundation
import Foundation
import ARKit
import SwiftyJSON

// MARK: Course

class Course {
  
    /// Course ID (ex. 1)
    var courseId: Int
  
    /**
     Initializes a new Course object, which can easily obtain relevant
     attendance information, and POST or GET requests to the
     respective API service. Course ID is needed to obtain the
     correct class of students, and their respective attendances.
   
     - Parameters:
     - courseId: Course ID
   
     - Returns: A Course that holds the resepctive course ID
     */
    init(courseId: Int) {
        self.courseId = courseId
    }
  
    // MARK: Methods to get and create list of Student objects
  
    /**
     A helper function that makes GET requests, and returns a JSON
     response (represented as nested dictionary in Swift)
   
     - Parameters:
     - getString: The String of the URL of the GET request
   
     - Returns: A JSON (nested dictionary) of the response from the request
     */
    func getRequest(getString : String) -> JSON {
        let url: NSURL = NSURL(string: getString)!
        let data = NSData(contentsOf: url as URL)!
        return try! JSON(data: data as Data)
    }
  
    /**
     Retrieves the enrollments for a specific course, and stores
     the student's andrew id locally.
   
     - Parameters:
     - None
   
     - Returns: A dictionary with Key as Andrew ID, and value
                as a list of the student's information (currently
                just the student's Andrew ID)
     */
    func getEnrollments() -> [String : [String:Any]] {
        var enrolledStudents = [String : [String:Any]]()
        let response = getRequest(getString: "https://attendify.herokuapp.com:443/enrollments")
        for anEnrollment in response {
            if (anEnrollment.1["course_id"].int == self.courseId) {
                let andrew = anEnrollment.1["andrew_id"].string ?? ""
                enrolledStudents[andrew] = ["andrew": andrew]
            }
        }
        return enrolledStudents
    }
  
    /**
     Retrieves and stores additional student information locally
     for the course.
   
     - Parameters:
     - CurrentDict: A dictionary with the Key as Andrew ID, and value
                    as a list that can hold student information
   
     - Returns: A dictionary with Key as Andrew ID, and value
                as a list of the student's information (now with Andrew ID,
                first and last name, and student ID number)
     */
    func getStudentsInfo(currentDict : [String : [String:Any]]) -> [String : [String:Any]] {
        var enrolledStudents:[String : [String:Any]] = currentDict
        let response = getRequest(getString: "https://attendify.herokuapp.com:443/students")
        for student in response {
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
  
    /**
     Retrieves and stores the photo URL for each student in the course, and stores
     it locally. If no photo exists, a default photo is used instead.
   
     - Parameters:
     - CurrentDict: A dictionary with the Key as Andrew ID, and value
     as a list that can hold student information
   
     - Returns: A dictionary with Key as Andrew ID, and value
     as a list of the student's information (now with Andrew ID,
     first and last name, student ID number, and photo URL)
     */
    func getphotos(currentDict : [String : [String:Any]]) -> [String : [String:Any]] {
      var enrolledStudents:[String : [String:Any]] = currentDict
      let defaultPhoto = "https://upload.wikimedia.org/wikipedia/commons/thumb/9/93/Default_profile_picture_%28male%29_on_Facebook.jpg/600px-Default_profile_picture_%28male%29_on_Facebook.jpg"
      for (andrew,_) in enrolledStudents {
        let aid = andrew
        let response = getRequest(getString: "https://attendify.herokuapp.com:443/photos?for_andrew_id=\(aid)")
        var state:Int = 0
        var photoURL:String = ""
        
        // There should only be 1 photo in allPhotos,
        // but just in case it will traverse for the first
        // usable image
        for photo in response {
          photoURL = photo.1["photo_url"].string ?? ""
          if (!photoURL.isEmpty) {
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
  
    /**
     Retrieves and stores the current attendance for the day,
     for the student in the current class; again, this will be
     stored locally to be eventually used to make Student instances
   
     - Parameters:
     - CurrentDict: A dictionary with the Key as Andrew ID, and value
     as a list that can hold student information
   
     - Returns: A dictionary with Key as Andrew ID, and value
     as a list of the student's information (now with Andrew ID,
     first and last name, student ID number, photo URL, attendance ID,
     and the attendance type/status)
     */
    func getTodayAttendances(currentDict : [String : [String:Any]]) -> [String : [String:Any]]  {
        var enrolledStudents:[String : [String:Any]] = currentDict
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        let today = Date()
        for (andrew,_) in enrolledStudents {
            let aid = andrew
            let response = getRequest(getString: "https://attendify.herokuapp.com:443/attendances?for_andrew_id=\(aid)&for_class=\(self.courseId)")
            var state = 0
          
            // For each student, look at all attendances for
            // that student in the class, and see if there is
            // one that is 'today'.
            // TODO: Adjust Swagger API to have a scope that handles this logic
            for attendance in response {
                let adateString = attendance.1["date"].string!.components(separatedBy: "T")[0]
                let adate = dateFormatter.date(from: adateString)
              if Calendar.current.compare(adate!, to: today, toGranularity: .day) == .orderedSame {
                        var lastInfo = enrolledStudents[aid]
                        lastInfo!["attendance_id"] = attendance.1["id"].int ?? 0
                        lastInfo!["status"] = attendance.1["attendance_type"].string
                        enrolledStudents[aid] = lastInfo
                        state = 1
                        break
                  }
            }
            if (state == 0) {
                var lastInfo = enrolledStudents[aid]
                lastInfo?["attendance_id"] = "No Attendance ID"
                lastInfo?["status"] = "Absent"
                enrolledStudents[aid] = lastInfo
            }
        }
        return enrolledStudents
    }
    
  
    /**
     Calls the previously defined methods to create a list of Student
     objects, which will be used by all controllers.
   
     - Parameters:
     - None
   
     - Returns: A list of Student objects that pertain to the current
                day, for the currently selected class.
     */
    func getStudents() -> [Student] {
        let enrolledStudents = self.getTodayAttendances(currentDict: getphotos(currentDict: getStudentsInfo(currentDict: getEnrollments())))
      
        let finalResponse = Dictionary(uniqueKeysWithValues:
            enrolledStudents.map { arg in (arg.key,
                                           Student(id: String(describing: arg.value["id"] ?? 0),
                                           name: arg.value["name"] as! String,
                                           andrew: arg.key,
                                           picture: arg.value["picture"] as! String,
                                           course_id: "1",
                                           status: arg.value["status"] as! String,
                                           attendance_id: String(describing: arg.value["attendance_id"] ?? 0)))})
        return Array(finalResponse.values)
        
    }
  
  /**
   This is a similar function to the getStudents() function, however this will instead
   get the entire current week of student data (used by PastRecordsController)
   
   - Parameters:
   - None
   
   - Returns: A dictionary with Key as Dates (local time) represented as String,
              and values as a list of Student objects that belong to the class
              (the idea being each student in each list has attendance data
              pertaining to the date, which again is the Key
   */
  func getWeekAttendances() -> [String : [Student]]  {
    var result : [String : [Student]] = [:]
    var enrolledStudents:[String : [String:Any]] = self.getphotos(currentDict: getStudentsInfo(currentDict: getEnrollments()))
    var today = Date()
    var prevDay = Calendar.current.date(byAdding: .day, value: -4, to: Date())!
    today = Calendar.current.date(byAdding: .day, value: +1, to: today)!
    // TODO: Fix this, as the <= comparison doesn't seem to add 'today'
    // attendance data. Right now, moved 'today' to 'tomorrow' which is a
    // quick hack
    while prevDay <= today {
      for (andrew,_) in enrolledStudents {
        let aid = andrew
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let response = getRequest(getString: "https://attendify.herokuapp.com:443/attendances?for_andrew_id=\(aid)&for_class=\(self.courseId)")
        var state = 0
        for attendance in response {
          let adateString = attendance.1["date"].string!.components(separatedBy: "T")[0]
          let adate = dateFormatter.date(from: adateString)
          if Calendar.current.compare(adate!, to: prevDay, toGranularity: .day) == .orderedSame {
            var lastInfo = enrolledStudents[aid]
            lastInfo!["attendance_id"] = attendance.1["id"].string ?? "No Attendance ID"
            lastInfo!["status"] = attendance.1["attendance_type"].string ?? "Absent"
            enrolledStudents[aid] = lastInfo
            state = 1
            break
          }
        }
        if (state == 0) {
          var lastInfo = enrolledStudents[aid]
          lastInfo?["attendance_id"] = "No Attendance ID"
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
 
  
    // MARK: The following method 'connects' our application with
    //       the Ruby on Rails API service, updating the appropiate
    //       attendance data (this is only called by the FaceRecognition
    //       controller.
  
    /**
     This function makes either a POST or PATCH request to the API service,
     creating a new attendance, or updating previous existing ones.
   
     - Parameters:
     -enrolledStudents: A list of Student objects, where we will use the Andrew
                        ID, attendance ID (if it exists) and status
   
     - Returns: Void
     */
    func updateAttendance(enrolledStudents: [Student], dateOfAttendance: Date) -> () {
        for student in enrolledStudents {
            let status = student.status
            var request:URLRequest
            var dict:[String:String]
            // If there does NOT exist a previous attendance record for this student
            // for the class for today
            if (student.attendance_id == "No Attendance ID") {
                let url = URL(string: "https://attendify.herokuapp.com:443/attendances")!
                request = URLRequest(url: url)
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue("application/json", forHTTPHeaderField: "Accept")
                request.httpMethod = "POST"
                dict = ["andrew_id": student.andrew, "date": "\(dateOfAttendance)", "course_id": student.course_id, "attendance_type": status]
            }
            else {
                // Otherwise, update an existing record with a PATCH request
                let url = URL(string: "https://attendify.herokuapp.com:443/attendances/" + student.attendance_id)
                request = URLRequest(url: url!)
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue("application/json", forHTTPHeaderField: "Accept")
                request.httpMethod = "PATCH"
                dict = ["id": student.attendance_id,"andrew_id": student.andrew, "date": "\(dateOfAttendance)", "course_id": student.course_id, "attendance_type": status]
            }
          print(student.andrew + ": " + request.httpMethod!)
            let jsonData = try! JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
            request.httpBody = jsonData
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let _ = data, error == nil else {    // check for fundamental networking error
                    print("error")
                    return
                }
                if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode == 201 {
                    print(response)
                }
            }
            task.resume()
        }
    }
  
    // MARK: Methods used by StatsViewController/HomeViewController
  
    /**
     Retrieves a list of Courses from the Ruby on Rails API, and
     returns
   
     - Parameters:
     - None
   
     - Returns: A list of tuples, where the first value is the class
                number, and the second value is the class ID
     */
    func getCourses() -> [(String,Int)] {
      let response = getRequest(getString: "https://attendify.herokuapp.com:443/courses")
      var allCourses : [(String,Int)] = [(String,Int)]()
      for course in response {
        allCourses.append((course.1["class_number"].string ?? "",course.1["id"].int ?? 1))
      }
      return allCourses
    }
  
    /**
     Parses out a list of the count of 'Present' students for the week,
     given a week of Student data
   
     - Parameters:
     - weekData: A dictionary where the Key is the date in String, and
                 the value is a list of Student objects for the class
                 for each date.
   
     - Returns: A dictionary where the Key is the date in String, and the
                value is an int representing the 'Present' count for each
                day.
     */
    func getWeeklyPresentCount(weekData : [String : [Student]]) -> [String : Int] {
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

    /**
     Get today's present count
   
     - Parameters:
     - weekData: A dictionary where the Key is the date in String, and
     the value is a list of Student objects for the class
     for each date.
   
     - Returns: A string representing today's present count
     */
    func calcToday(weeklyPresentCount : [String : Int]) -> String {
        let weeklyPresentCount = weeklyPresentCount
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let adate = dateFormatter.string(from: Date())
        return String(weeklyPresentCount[adate] ?? 0)
      }
  
    /**
     Calculate week's average attendance (including days with 0
     attendance)
   
     - Parameters:
     - weekData: A dictionary where the Key is the date in String, and
     the value is a list of Student objects for the class
     for each date.
   
     - Returns: A string representing the average present count
     */
    func calcWeekAverage(weeklyPresentCount : [String : Int]) -> String {
        let weeklyPresentCount = weeklyPresentCount
        let avgResult = Double(weeklyPresentCount.reduce(0, { x, y in
          x + y.value
        })) / Double(weeklyPresentCount.count)
        if (!avgResult.isNaN) {
          return String(avgResult)
        }
        return "0"
    }
  
    /**
     Calculate week's maximum attendance (including days with 0
     attendance)
   
     - Parameters:
     - weekData: A dictionary where the Key is the date in String, and
     the value is a list of Student objects for the class
     for each date.
   
   - Returns: A tuple representing the minimum present count, with
              the first value as the date of the maximum number of
              present students, and the second value with the actual
              count.
     */
    func calcWeekMax(weeklyPresentCount : [String : Int]) -> (String,String) {
      let weeklyPresentCount = weeklyPresentCount
      let maxAttendance = String(weeklyPresentCount.reduce(Int.min, { x, y in
        max(x,y.value)}))
      let date = (weeklyPresentCount as NSDictionary).allKeys(for: Int(maxAttendance)) as! [String]
      if (date.count != 0) {
        return (date[0], maxAttendance)
      }
      return ("0","0")
    }
  
    /**
     Calculate week's minimum attendance (including days with 0
     attendance)
   
     - Parameters:
     - weekData: A dictionary where the Key is the date in String, and
     the value is a list of Student objects for the class
     for each date.
   
     - Returns: A tuple representing the minimum present count, with
                the first value as the date of the minimum number of
                present students, and the second value with the actual
                count.
     */
    func calcWeekMin(weeklyPresentCount : [String : Int]) -> (String,String) {
      let weeklyPresentCount = weeklyPresentCount
      let minAttendance = String(weeklyPresentCount.reduce(Int.max, { x, y in
        min(x,y.value)}))
      let date = (weeklyPresentCount as NSDictionary).allKeys(for: Int(minAttendance)) as! [String]
      if (date.count != 0) {
        return (date[0], minAttendance)
      }
      return ("0","0")
    }
  
  
}
