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
  
  @IBOutlet weak var averageCard: UIButton!
  @IBOutlet weak var todayCard: UIButton!
  @IBOutlet weak var highestCard: UIButton!
  @IBOutlet weak var lowestCard: UIButton!
  @IBOutlet weak var barChart: BarChartView!
  var days: [String]!

  override func viewDidLoad() {
    super.viewDidLoad()
    let weekOfData = HomeViewController().weekOfData
    days = weekOfData.map { $0.0.components(separatedBy: "-")[2].components(separatedBy: "T")[0] }
    let attendanceCount = weekOfData.map { Double($0.1) }
    
    setChart(dataPoints: days, values: attendanceCount)
    self.view.backgroundColor = .white
    averageCard.setTitle(HomeViewController().weekDataAvg, for: .normal)
    todayCard.setTitle(HomeViewController().weekDataToday, for: .normal)
    highestCard.setTitle(HomeViewController().weekDataMax.1, for: .normal)
    lowestCard.setTitle(HomeViewController().weekDataMin.1, for: .normal)
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  func setChart(dataPoints: [String], values: [Double]) {
//    barChart.noDataText = "You need to provide data for the chart."

    var dataEntries: [BarChartDataEntry] = []
    
    for i in 0..<dataPoints.count {
      let dataEntry = BarChartDataEntry(x: Double(dataPoints[i]) ?? 0.0, y: values[i])
      dataEntries.append(dataEntry)
    }
    
    let chartDataSet = BarChartDataSet(values: dataEntries, label: "Attendance count")
    let chartData = BarChartData(dataSet: chartDataSet)
    barChart.data = chartData
    chartDataSet.colors = ChartColorTemplates.colorful()
    barChart.animate(xAxisDuration: 2.0, yAxisDuration: 2.0)

    
  }
  
  
  
  
}
