//
//  FacerecognitionController.swift
//  faceIT

import UIKit
import SceneKit
import ARKit
import Vision

import RxSwift
import RxCocoa
import Async
import PKHUD

class FacerecognitionController: UIViewController, UITableViewDataSource, UITableViewDelegate, ARSCNViewDelegate{
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var tableview: UITableView!
    @IBOutlet var statusBarView: UIView!
    @IBOutlet var numPresent:UILabel!
    @IBOutlet var numAbsent:UILabel!
    @IBOutlet var doneButton: UIButton!
    
    var 👜 = DisposeBag()
    
    var faces: [Face] = []
//    let course = Course.init(courseId: 1)
    var attendance: [Student] = todayAttendance
  
    var bounds: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        for student in attendance{
            if( student.status == "Optional(Present)"){student.status = "Present"}
            if( student.status == "Optional(Absent)"){student.status = "Absent"}
        }
        
        //rounded corners
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
        self.tableview.layer.cornerRadius = 10
        self.tableview.layer.masksToBounds = true
        self.statusBarView.layer.cornerRadius = 10
        self.statusBarView.layer.masksToBounds = true
        self.doneButton.layer.cornerRadius = 10
        self.doneButton.layer.masksToBounds = true
//        refreshLabels()
        bounds = sceneView.bounds
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)

        
        
        Observable<Int>.interval(1, scheduler: SerialDispatchQueueScheduler(qos: .default))
            .subscribeOn(SerialDispatchQueueScheduler(qos: .background))
            .concatMap{ _ in  self.faceObservation() }
            .flatMap{ Observable.from($0)}
            .flatMap{ self.faceClassification(face: $0.observation, image: $0.image, frame: $0.frame, models: model) }
            .subscribe { [unowned self] event in
                guard let element = event.element else {
                    print("No element available")
                    return
                }
                self.updateNode(classes: element.classes, position: element.position, frame: element.frame)
            }.disposed(by: 👜)
        
        
        Observable<Int>.interval(1, scheduler: SerialDispatchQueueScheduler(qos: .default))
            .subscribeOn(SerialDispatchQueueScheduler(qos: .background))
            .subscribe { [unowned self] _ in
                
                self.faces.filter{ $0.updated.isAfter(seconds: 1) && !$0.hidden }.forEach{ face in
                    print("Hide node: \(face.name)")
                    Async.main {
                        face.node.hide()
                    }
                }
            }.disposed(by: 👜)
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
        Async.main{
            self.tableview.reloadData()
            self.refreshLabels()
        }
//        self.tableview.reloadData()
//        self.refreshLabels()
    }
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return attendance.count
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if (attendance[indexPath.row].status == "Present" || attendance[indexPath.row].status == "Optional(Present)")
        {
            attendance[indexPath.row].status = "Present"
            cell.backgroundColor = UIColor(red: 0.8549, green: 0.9686, blue: 0.6863, alpha: 1.0)

        }
        else{
            cell.backgroundColor = UIColor(red: 0.9686, green: 0.7294, blue: 0.6863, alpha: 1.0)
        }
        self.refreshLabels()
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

       
    }
    
    func refreshLabels(){
        Async.main {
            self.numPresent.text = "\(self.attendance.reduce(0){$1.status == "Present" ? $0+1 : $0})"
            self.numAbsent.text = "\(self.attendance.reduce(0){$1.status == "Absent" ? $0+1 : $0})"
        }
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {

        switch camera.trackingState {
//        case .limited(.initializing):
//            PKHUD.sharedHUD.contentView = PKHUDProgressView(title: "Initializing", subtitle: nil)
//            PKHUD.sharedHUD.show()
        case .notAvailable:
            print("Not available")
        default:
            PKHUD.sharedHUD.hide()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        👜 = DisposeBag()
        sceneView.session.pause()
    }
    
    // MARK: - Face detections
    private func faceObservation() -> Observable<[(observation: VNFaceObservation, image: CIImage, frame: ARFrame)]> {
        return Observable<[(observation: VNFaceObservation, image: CIImage, frame: ARFrame)]>.create{ observer in
            guard let frame = self.sceneView.session.currentFrame else {
                print("No frame available")
                observer.onCompleted()
                return Disposables.create()
            }
            
            // Verify tracking state and abort
            guard case .normal = frame.camera.trackingState else {
                print("Tracking not available: \(frame.camera.trackingState)")
                observer.onCompleted()
                return Disposables.create()
            }
            
            // Create and rotate image
            let image = CIImage.init(cvPixelBuffer: frame.capturedImage).rotate
            
            let facesRequest = VNDetectFaceRectanglesRequest { request, error in
                guard error == nil else {
                    print("Face request error: \(error!.localizedDescription)")
                    observer.onCompleted()
                    return
                }
                
                guard let observations = request.results as? [VNFaceObservation] else {
                    print("No face observations")
                    observer.onCompleted()
                    return
                }
                
                // Map response
                let response = observations.map({ (face) -> (observation: VNFaceObservation, image: CIImage, frame: ARFrame) in
                    return (observation: face, image: image, frame: frame)
                })
                observer.onNext(response)
                observer.onCompleted()
                
            }
            try? VNImageRequestHandler(ciImage: image).perform([facesRequest])
            
            return Disposables.create()
        }
    }
    
    private func faceClassification(face: VNFaceObservation, image: CIImage, frame: ARFrame, models: VNCoreMLModel) -> Observable<(classes: [VNClassificationObservation], position: SCNVector3, frame: ARFrame)> {
        return Observable<(classes: [VNClassificationObservation], position: SCNVector3, frame: ARFrame)>.create{ observer in
            
            // Determine position of the face
            let boundingBox = self.transformBoundingBox(face.boundingBox)
            guard let worldCoord = self.normalizeWorldCoord(boundingBox) else {
                print("No feature point found")
                observer.onCompleted()
                return Disposables.create()
            }
            
            // Create Classification request
            let request = VNCoreMLRequest(model: models, completionHandler: { request, error in
                guard error == nil else {
                    print("ML request error: \(error!.localizedDescription)")
                    observer.onCompleted()
                    return
                }
                
                guard let classifications = request.results as? [VNClassificationObservation] else {
                    print("No classifications")
                    observer.onCompleted()
                    return
                }
                
                observer.onNext(classes: classifications, position: worldCoord, frame: frame)
                observer.onCompleted()
            })
            request.imageCropAndScaleOption = .scaleFit
            
            do {
                let pixel = image.cropImage(toFace: face)
                try VNImageRequestHandler(ciImage: pixel, options: [:]).perform([request])
            } catch {
                print("ML request handler error: \(error.localizedDescription)")
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
    
    private func updateNode(classes: [VNClassificationObservation], position: SCNVector3, frame: ARFrame) {
        
        guard let person = classes.first else {
            print("No classification found")
            return
        }
        
        let second = classes[1]
        let name = person.identifier
        print("""
            FIRST
            confidence: \(person.confidence) for \(person.identifier)
            SECOND
            confidence: \(second.confidence) for \(second.identifier)
            
            """)
        if person.confidence < 0.60 || person.identifier == "unknown" {
            print("not so sure")
            return
        }
        
        // Filter for existent face
        let results = self.faces.filter{ $0.name == name && $0.timestamp != frame.timestamp }
            .sorted{ $0.node.position.distance(toVector: position) < $1.node.position.distance(toVector: position) }
        
        var person_name = "Not sure"
        // Create new face
        guard let existentFace = results.first else {
            
            for student in attendance{
                if (student.andrew == name && person.confidence > 0.6){person_name = student.name}
            }
            
            DispatchQueue.main.async {
//                self.face_identified.text = person_name
//                self.confidence.text = "\(person.confidence)"
            }
            let node = SCNNode.init(withText: person_name, position: position)
            
            Async.main {
//                self.tableview.reloadData()
                self.refreshLabels()
                self.sceneView.scene.rootNode.addChildNode(node)
                node.show()
                
            }
            let face = Face.init(name: person_name, node: node, timestamp: frame.timestamp)
            self.faces.append(face)

            
            for s in attendance{
                if(s.andrew == name)
                {
                   s.status = "Present"
                    
                    Async.main{
                        let url = URL(string: (s.picture))!
                        let data = try! Data(contentsOf: url)
                        self.view.makeToast("\(s.name) was marked for attendance", duration: 1.5, position: .center, image: UIImage(data: data))
                        self.tableview.reloadData()
                        self.refreshLabels()
                    }
                }
            }
            return
        }
        
        // Update existent face
        Async.main {
//            self.tableview.reloadData()
            
            // Filter for face that's already displayed
//            self.view.hideAllToasts()
            if let displayFace = results.filter({ !$0.hidden }).first  {
                
                let distance = displayFace.node.position.distance(toVector: position)
                if(distance >= 0.03 ) {
                    displayFace.node.move(position)
                }
                displayFace.timestamp = frame.timestamp
                
            } else {
                existentFace.node.position = position
                existentFace.node.show()
                existentFace.timestamp = frame.timestamp
            }
        }
    }


    /// In order to get stable vectors, we determine multiple coordinates within an interval.
    ///
    /// - Parameters:
    ///   - boundingBox: Rect of the face on the screen
    /// - Returns: the normalized vector
    private func normalizeWorldCoord(_ boundingBox: CGRect) -> SCNVector3? {
        
        var array: [SCNVector3] = []
        Array(0...2).forEach{_ in
            if let position = determineWorldCoord(boundingBox) {
                array.append(position)
            }
            usleep(12000) // .012 seconds
        }

        if array.isEmpty {
            return nil
        }
        
        return SCNVector3.center(array)
    }
    
    @IBAction func submit_attendance(sender: UIButton){
        for student in attendance{
            print(student.name, student.status)
        }
        course.updateAttendance(enrolledStudents: attendance)
        weekOfAttendance = course.getWeekAttendances()
        weekOfAttendanceCount = course.getWeeklyAttendance(weekData: weekOfAttendance)
    }
    
    /// Determine the vector from the position on the screen.
    ///
    /// - Parameter boundingBox: Rect of the face on the screen
    /// - Returns: the vector in the sceneView
    private func determineWorldCoord(_ boundingBox: CGRect) -> SCNVector3? {
        let arHitTestResults = sceneView.hitTest(CGPoint(x: boundingBox.midX, y: boundingBox.midY), types: [.featurePoint])
        
        // Filter results that are to close
        if let closestResult = arHitTestResults.filter({ $0.distance > 0.10 }).first {
//            print("vector distance: \(closestResult.distance)")
            return SCNVector3.positionFromTransform(closestResult.worldTransform)
        }
        return nil
    }
    
    
    /// Transform bounding box according to device orientation
    ///
    /// - Parameter boundingBox: of the face
    /// - Returns: transformed bounding box
    private func transformBoundingBox(_ boundingBox: CGRect) -> CGRect {
        var size: CGSize
        var origin: CGPoint
        switch UIDevice.current.orientation {
        case .landscapeLeft, .landscapeRight:
            size = CGSize(width: boundingBox.width * bounds.height,
                          height: boundingBox.height * bounds.width)
        default:
            size = CGSize(width: boundingBox.width * bounds.width,
                          height: boundingBox.height * bounds.height)
        }
        
        switch UIDevice.current.orientation {
        case .landscapeLeft:
            origin = CGPoint(x: boundingBox.minY * bounds.width,
                             y: boundingBox.minX * bounds.height)
        case .landscapeRight:
            origin = CGPoint(x: (1 - boundingBox.maxY) * bounds.width,
                             y: (1 - boundingBox.maxX) * bounds.height)
        case .portraitUpsideDown:
            origin = CGPoint(x: (1 - boundingBox.maxX) * bounds.width,
                             y: boundingBox.minY * bounds.height)
        default:
            origin = CGPoint(x: boundingBox.minX * bounds.width,
                             y: (1 - boundingBox.maxY) * bounds.height)
        }
        
        return CGRect(origin: origin, size: size)
    }
}


