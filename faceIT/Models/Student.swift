//
//  Student.swift
//  faceIT
//  Updated by Arnav Gupta
//  Last updated: December 6th, 2018

import Foundation
import ARKit

// MARK: Student
// TODO: Change id variables from String to Int

class Student {
  
    /// Student ID (ex. 1)
    let id: String
  
    /// Full name (ex. George Yao)
    let name: String
  
    /// AndrewID (ex. gyao)
    let andrew: String
  
    /// Status (One of "Present", "Absent", "Excused")
    var status: String
  
    /// URL for photo (ex. s3.amazonaws.com/BUCKET_NAME/OBJECT_NAME.jpg)
    let picture: String
  
    /// Course ID (ex. 1 for 67-272)
    let course_id: String
  
    /// attendance ID (ex. 1)
    let attendance_id: String
  
    /**
     Initializes a new student with the provided information. Note that the
     values for the ID (id, course_id, attendance_id correspond to the PK values
     in the Ruby on Rails application). We ended up making a String type as a means
     of getting our idea out.
   
     - Parameters:
     - id: Student ID
     - name: The full name of the student
     - andrew: The AndrewID of the student
     - picture: The URL of the student's first photo
     - course_id: The course id respective to that of all courses
     - status: A status indicating whether the student is 'Present', 'Absent' or 'Excused'
     - attendance_id: The attendance id representing the student's attendance for a day for a class
   
     - Returns: A student with relevant information within a course
     */

    init(id: String, name: String, andrew: String, picture: String, course_id: String, status: String, attendance_id: String) {
          self.id = id
          self.name = name
          self.andrew = andrew
          self.status = status
          self.picture = picture
          self.course_id = course_id
          self.attendance_id = attendance_id
      }
}
