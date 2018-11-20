//
//  StudentTests.swift
//  AttendifyTests
//
//  Created by Arnav Gupta on 11/9/18.
//  Copyright © 2018 NovaTec GmbH. All rights reserved.
//

import XCTest
import Foundation
//@testable import faceIT

class StudentTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        

    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testStudentStruct() {
        // This is an example of a performance test case.
//        let attendance: [Student] = [Student.init(id: "1", name: "Arnav", andrew: "ag", picture: "agn", course_id: "1", status: "Present", attendance_id: "1")]
        XCTAssertEqual(attendance.count, 2)
    }

}
