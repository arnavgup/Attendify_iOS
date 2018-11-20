//
//  HomeViewController.swift
//  faceIT
//
//  Created by Arnav Gupta on 11/9/18.

import UIKit
import SceneKit
import ARKit
import Vision

import RxSwift
import RxCocoa
import Async
import PKHUD

var mlmodel = Faces_v4().model
var model: VNCoreMLModel = try! VNCoreMLModel(for: Faces_v4().model)

class HomeViewController: UIViewController {

    @IBOutlet var startAttendanceButton: UIButton!
    @IBOutlet var statsButton: UIButton!
    @IBOutlet var courseButton: UIButton!
    @IBOutlet var manualAddButton: UIButton!
    @IBOutlet var downloadStatus: UILabel!
    @IBOutlet var activityView: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        activityView.startAnimating()
        self.downloadStatus.text = "Fetching latest model"
        self.startAttendanceButton.layer.cornerRadius = 10
        self.startAttendanceButton.layer.masksToBounds = true
        self.startAttendanceButton.isEnabled = false
        self.statsButton.layer.cornerRadius = 10
        self.statsButton.layer.masksToBounds = true
        self.courseButton.layer.cornerRadius = 10
        self.courseButton.layer.masksToBounds = true
        self.manualAddButton.layer.cornerRadius = 10
        self.manualAddButton.layer.masksToBounds = true
        
        //         Create destination URL
        let documentsUrl:URL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first as URL!
        let destinationFileUrl = documentsUrl.appendingPathComponent("Download\(Int.random(in: 0 ... 10000)).mlmodel")
        
        self.download(destinationFileUrl: destinationFileUrl) { (output) in
            DispatchQueue.main.async{
                do {
                    let compiledUrl = try MLModel.compileModel(at: destinationFileUrl)
                    mlmodel = try MLModel(contentsOf: compiledUrl)
                    self.activityView.stopAnimating()
                    self.downloadStatus.text = "Got the latest model, ready!"
                    self.startAttendanceButton.isEnabled = true

                } catch {
                    print("Unexpected error: \(error).")
                }
                
                model = try! VNCoreMLModel(for: mlmodel)
            }
        }
        // Do any additional setup after loading the view.
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
