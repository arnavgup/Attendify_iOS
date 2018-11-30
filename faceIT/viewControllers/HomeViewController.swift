//
//  HomeViewController.swift
//  faceIT
//
//  Created by Arnav Gupta on 11/9/18.

import UIKit
import SceneKit
import ARKit
import Vision
import ObjectiveC
import RxSwift
import RxCocoa
import Async
import PKHUD
import Toast_Swift

var course = Course.init(courseId: 1)
var courseId = 1
var todayAttendance: [Student] = course.getStudents().sorted(by: { $0.name > $1.name })
var weekOfAttendance: [String : [Student]] = course.getWeekAttendances()
var weekOfAttendanceCount : [String : Int] = course.getWeeklyAttendance(weekData: weekOfAttendance)
var weekOfData : [String : Int] = course.getWeeklyAttendance(weekData: weekOfAttendance)
var weekDataAvg : String = ""
var weekDataToday  : String = ""
var weekDataMax : (String, String) = ("","")
var weekDataMin : (String, String) = ("","")

class HomeViewController: UIViewController, ARSCNViewDelegate {
    var mlmodel = Faces_v4().model
    var model: VNCoreMLModel = try! VNCoreMLModel(for: Faces_v4().model)
    var courseIndex = 0

    @IBOutlet var startAttendanceButton: UIButton!
    @IBOutlet var statsButton: UIButton!
    @IBOutlet var courseButton: UIButton!
    @IBOutlet var manualAddButton: UIButton!
    @IBOutlet var downloadStatus: UILabel!
    @IBOutlet var activityView: UIActivityIndicatorView!
//    @IBOutlet var barButtonItem: UIBarButtonItem!
    @IBOutlet var sceneView: ARSCNView!
    override func viewDidLoad() {
        super.viewDidLoad()
        activityView.startAnimating()
        
        //rounded corners
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
        self.sceneView.layer.cornerRadius = 10
        self.sceneView.layer.masksToBounds = true
        self.downloadStatus.text = modelStatus
        self.startAttendanceButton.layer.cornerRadius = 10
        self.startAttendanceButton.layer.masksToBounds = true
//        self.startAttendanceButton.isEnabled = false
        self.statsButton.layer.cornerRadius = 10
        self.statsButton.layer.masksToBounds = true
        self.courseButton.layer.cornerRadius = 10
        self.courseButton.layer.masksToBounds = true
        self.manualAddButton.layer.cornerRadius = 10
        self.manualAddButton.layer.masksToBounds = true
//        barButtonItem.image = UIImage(named: "menu")
//        //         Create destination URL
//        let documentsUrl:URL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first as URL!
//        let destinationFileUrl = documentsUrl.appendingPathComponent("Download\(Int.random(in: 0 ... 10000)).mlmodel")
//        
//        self.download(destinationFileUrl: destinationFileUrl) { (output) in
//            DispatchQueue.main.async{
//                do {
//                    let compiledUrl = try MLModel.compileModel(at: destinationFileUrl)
//                    mlmodel = try MLModel(contentsOf: compiledUrl)
//                    self.activityView.stopAnimating()
//                    self.downloadStatus.text = "Got the latest model, ready!"
//                    self.startAttendanceButton.isEnabled = true
//
//                } catch {
//                    print("Unexpected error: \(error).")
//                }
//
//                model = try! VNCoreMLModel(for: mlmodel)
//            }
//        }
        // Do any additional setup after loading the view.
      print("Updating")
      weekOfAttendance = course.getWeekAttendances()
      weekOfAttendanceCount = course.getWeeklyAttendance(weekData: weekOfAttendance)
      weekOfData = course.getWeeklyAttendance(weekData: weekOfAttendance)
      weekDataAvg = course.calcWeekAverage(weeklyAttendance: weekOfData)
      weekDataToday = course.calcToday(weeklyAttendance: weekOfData)
      weekDataMax = course.calcWeekMax(weeklyAttendance: weekOfData)
      weekDataMin = course.calcWeekMin(weeklyAttendance: weekOfData)
      print("Updated")
      print(weekDataAvg)
      print(weekDataToday)
      print(weekDataMax)
      print(weekDataMin)
      print(weekOfData)
  }
    
    func download(destinationFileUrl: URL, completionBlock: @escaping (String) -> Void) {
        //Create URL to the source file you want to download
        DispatchQueue.main.async{
            let fileURL = URL(string: "http://attendify.us-east-1.elasticbeanstalk.com/models/download")
            let sessionConfig = URLSessionConfiguration.default
            let session = URLSession(configuration: sessionConfig)
            let request = URLRequest(url:fileURL!)
            let task = session.downloadTask(with: request) { (tempLocalUrl, response, error) in
                if let tempLocalUrl = tempLocalUrl, error == nil {
                    // Success
                    if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                        completionBlock("done")
                        print("Successfully downloaded. Status code: \(statusCode)")
                    }
                    do {
                        try FileManager.default.copyItem(at: tempLocalUrl, to: destinationFileUrl)
                    } catch (let writeError) {
                        print("Error creating a file \(destinationFileUrl) : \(writeError)")
                    }
                } else {
                    print("Error took place while downloading a file. Error description: %@", error?.localizedDescription ?? "nil");
                }
            }
            
            task.resume()
        }
    }
  
  @IBAction func changeCourse(_ sender: AnyObject) {
    print("Button tap leads to function call")
    let allCourses = course.getCourses()
    courseIndex += 1
    if (courseIndex > allCourses.count - 1) {
      courseIndex = 0
    }
    courseId = allCourses[courseIndex].1
    course = Course.init(courseId: courseId)
    sender.setTitle(allCourses[courseIndex].0, for: .normal)
  }
}
