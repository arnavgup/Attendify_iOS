//
//  Student.swift
//  faceIT
//
//  Created by Arnav Gupta on 11/8/18.
//

import Foundation
import ARKit

class Student {
  
    let id: String
    let name: String
    let andrew: String
    var status: String
    let picture: String
    let course_id: String
    let attendance_id: String


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
