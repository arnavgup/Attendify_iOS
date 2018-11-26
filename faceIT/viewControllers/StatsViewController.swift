//
//  StatsViewController.swift
//  faceIT
//
//  Created by George Yao on 11/22/18.
//  Copyright © 2018 NovaTec GmbH. All rights reserved.
//

import UIKit
import Charts


class StatsViewController: UIViewController{
  
  @IBOutlet weak var barChart: BarChartView!
  var days: [String]!

  override func viewDidLoad() {
    super.viewDidLoad()
    var attendanceArray = [String]()
    let calendar = Calendar.current
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    
//    for i in 0 ..< attendanceArray.count {
//      days = attendanceArray.reduce(days, {x,y in
//        let adate = dateFormatter.date(from: attendanceArray[i])
//        let day = calendar.component(.day, from: adate!)
//        y[day] = 0
//    }
    
    days = ["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17",
              "18","19","20","21","22","23","24","25","26","27","28","29","30","31"]
    let attendanceCount = [Double](repeating: 20.0, count: 31)
    setChart(dataPoints: days, values: attendanceCount)
    self.view.backgroundColor = .white

  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  func setChart(dataPoints: [String], values: [Double]) {
//    barChart.noDataText = "You need to provide data for the chart."

    var dataEntries: [BarChartDataEntry] = []
    
    for i in 0..<dataPoints.count {
      let dataEntry = BarChartDataEntry(x: Double(dataPoints[i])!, y: values[i])
      dataEntries.append(dataEntry)
    }
    
    let chartDataSet = BarChartDataSet(values: dataEntries, label: "Attendance count")
    let chartData = BarChartData(dataSet: chartDataSet)
    barChart.data = chartData
    chartDataSet.colors = ChartColorTemplates.colorful()
    barChart.animate(xAxisDuration: 2.0, yAxisDuration: 2.0)

    
  }
  
  
}
