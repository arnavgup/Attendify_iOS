<h1 align="center"> Attendify </h1> <br>
<p align="center">
  <img src="faceIT/Images.xcassets/Attendify-logo.png" width="30%">
</p>
<p align="center">
  Attendance made easy
</p>


## Table of Contents
* [Team Members](#team-members)
* [Features](#introduction)
* [How does it Work](#how-does-it-work)
* [Getting Started](#getting-started)
<!-- * [Tests](#tests) -->
* [Built with](#built-with)
* [Acknowledgments](#acknowledgments)
* [License](#license)


## Team Members

* [**Arnav Gupta**](https://github.com/arnavgup) - *Lead UX Designer, Backend Developer, Database Administrator, QA Testing*
* [**George Yao**](https://github.com/gyao852) - *Lead Systems Architect, Full-stack Developer, Data Engineer, QA Testing*

See also a list of those that helped us throughout our project development [here](#acknowledgments).

## Introduction
Attendify is a project we created for 67-442 'Mobile Application Development in iOS' at Carnegie Mellon University (under the Information Systems program). We wanted to address the tedious, time-consuming process of obtaining class attendance for professors. Current attendance systems in place vary in degrees of efficiency and accuracy. For example, paper sign leads to long queues, while iClickers can be easily cheated with a single student answering for his/her peers. With this in mind, we wanted to experience building something with  with Apple's ARKit and CoreML frameworks, as both had exciting new updates this year. Thus comes Attendify, an iOS application that allows professors to take and manage attendance through facial recognition.

## Features
TODO

## How does it work
TODO

## Getting Started

The following instructions will help you get set up with building the application locally on your computer. Ideally, this should be done on an OSX system, as the preferred IDE for IOS development is Xcode.

**NOTE:** While you may be able to build the application successfully on your local machine, it will NOT run properly if the Flask Web-app (Github link here) OR the Ruby on Rails API Service are not running alongside. This is because this iOS application relies on getting the latest .mlmodel file from the Flask web-site, and is currently set to upload data to the Ruby on Rails API service.


### Prerequisites

* Xcode 9+
* Swift 4+
* iPhone 6s Device or above
* Ruby 2+
  ```
  $ sudo brew install ruby
  ```
  **Note:** If you do not have Homebrew, follow instructions [here](https://brew.sh/)
* Cocoapods
  ```
  $ sudo gem install cocoapods
  $ pod setup
  ```


### Setup and Installation

First, download the repository to your local machine
```
git clone git@github.com:arnavgup/Attendify_iOS.git
```
We need to set up cocoapods for this project with the following commands.
```
$ cd faceIT
$ pod init
$ pod install
```
Open up faceIT.xcodeproj in Xcode. If you have an iPhone 6S or above device, plug it into your computer now.

Simply click on the play button at the top left to build and run the project. If you plugged in your iPhone device, it should automatically install on your phone and run locally there; otherwise it will run within XCode's iPhone simulator.

**NOTE:** If you attempt to open this in Xcode Simulator, note that the camera view will NOT work, as that feature is not supported. Load the application onto your iPhone 6s or above device instead.

**Note** If you cannot build the project, and there arises 80+ compile issues, it is likely that the Swift compile version for the used libraries is not set to 4.x. Within Xcode, on the left hand navigation bar click on the Pods file. Underneath TARGETS, check to make sure that the Swift Language Version is set to Swift 4 or Swift 4.2 for Charts, SwiftyJSON and Toast-Swift via Build Settings -> Basic-> Swift Compiler - Language -> Swift Language Version.


<!-- ## Tests

Explain how to run the automated tests for this system

### Break down into end to end tests

Explain what these tests test and why

```
Give an example
``` -->

## Built With
* [ARKit 2](https://developer.apple.com/arkit/) - Used to detect faces through facial Nodes, and present text in 3-D space real time

* [Core ML](https://developer.apple.com/documentation/coreml) - Used to run and apply model within iOS environment

* [Turi Create](https://github.com/apple/turicreate) - Used to create the resnet-50 model in .mlmodel form

* [Cocoapods](https://cocoapods.org/) - Used as a dependency manager for Swift projects

* [Flask](http://flask.pocoo.org/) - Used to build our front-end web application that houses the registration form, and trains the resnet-50 model

* [Ruby on Rails](https://rubyonrails.org/) - Used to create an API service to act as our endpoints

* [Git](https://git-scm.com/) - Used for version control


## Acknowledgments
* **NovaTec Consulting**

  We based the AR view component of our project from their [example](https://github.com/NovatecConsulting/FaceRecognition-in-ARKit). They used Vision-API to run the extracted faces against their model, and similarly ran the extracted student faces against our pre-trained resnet-50 model. Their example was what inspired us into believing that we can truly achieve something really cool using AR Kit and CoreML.

* **Gorilla Logic**

  Gorilla Logic had a [piece](https://gorillalogic.com/blog/how-to-build-a-face-recognition-app-in-ios-using-coreml-and-turi-create-part-2/) showing a step-by-step process of their face recognition application. Most importantly, we learned about Turi Create, and how to use their library to create the model within a Flask (python) environment.

* **Jose Vazquez** - *Lead iOS engineer/Senior Manager at Capital One*

  Jose acted as our project mentor, advising us all the way from the start with the ideation process, to our final project iteration. He gave a lot of useful insight regarding iOS design patterns, important notes regarding user-testing, as well as early technical support regarding compiling the ML model at run-time.

* **Professor Larry Heimann** - *Information Systems Teaching Professor at Carnegie Mellon University*

  Professor Heimann allowed us to perform several user-testing during his classes, allowing us to attempt to try the application in a more appropriate testing environment (as opposed to individual testing amongst our friends). He also provided a lot of useful feedback regarding UX, and the overall design usage for the application.

* **Frank Liao, Jordan Stapinski, Kenny Cohen** - *67-442 Teaching Assistants*

  The course TAs provided useful feedback throughout each project sprint, and we ultimately incorporated a lot of their feedback into our UI and system design.


## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details
