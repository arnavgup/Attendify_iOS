//
//  AttendifyTests.swift
//  AttendifyTests
//
//  Created by Arnav Gupta on 11/9/18.
//

import XCTest
@testable import faceIT

class AttendifyTests: XCTestCase {
    let course = Course.init(courseId: 1)
  
    override func setUp() {
      
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
      print(course.getStudents())
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }



}
