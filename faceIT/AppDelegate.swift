//
//  AppDelegate.swift
//  faceIT
//

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

var mlmodel = Faces_v4().model
var model: VNCoreMLModel = try! VNCoreMLModel(for: Faces_v4().model)
var modelStatus = "ML model is expired, please wait"
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let documentsUrl:URL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first as URL!
        let destinationFileUrl = documentsUrl.appendingPathComponent("Download\(Int.random(in: 0 ... 10000)).mlmodel")
        let today : String!
        
        today = getTodayString()
        
        modelStatus = today
//        download(destinationFileUrl: destinationFileUrl) { (output) in
//            DispatchQueue.main.async{
//                do {
//                    let compiledUrl = try MLModel.compileModel(at: destinationFileUrl)
//                    mlmodel = try MLModel(contentsOf: compiledUrl)
////                    self.activityView.stopAnimating()
////                    self.downloadStatus.text = "Got the latest model, ready!"
////                    self.startAttendanceButton.isEnabled = true
//
//                } catch {
//                    print("Unexpected error: \(error).")
//                }
//
//                model = try! VNCoreMLModel(for: mlmodel)
//            }
//
//        }
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
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
    // Get today date as String
    
    func getTodayString() -> String{
        
        let date = Date()
        let calender = Calendar.current
        let components = calender.dateComponents([.year,.month,.day,.hour,.minute,.second], from: date)
        
        let year = components.year
        let month = components.month
        let day = components.day
        let hour = components.hour
        let minute = components.minute
        let second = components.second
        
        let today_string = String(year!) + "-" + String(month!) + "-" + String(day!) + " " + String(hour!)  + ":" + String(minute!) + ":" +  String(second!)
        
        return today_string
        
    }
    

}

