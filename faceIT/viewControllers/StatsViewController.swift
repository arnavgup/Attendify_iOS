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
  weak var axisFormatDelegate: IAxisValueFormatter?
  var months: [String]! //= ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
  
  
  var days: [String]!
  
  override func viewDidLoad() {
    super.viewDidLoad()
//    axisFormatDelegate = self
    self.view.backgroundColor = .white
    barChart.invalidateIntrinsicContentSize()
    let weekData = weekOfData
    days = weekData.map { $0.0.components(separatedBy: "-")[1]+"/"+$0.0.components(separatedBy: "-")[2].components(separatedBy: "T")[0] }
    let attendanceCount = weekData.map { Double($0.1) }
    averageCard.setTitle(weekDataAvg, for: .normal)
    todayCard.setTitle(weekDataToday, for: .normal)
    highestCard.setTitle(weekDataMax.1, for: .normal)
    lowestCard.setTitle(weekDataMin.1, for: .normal)
    setup(chartView: barChart)
    populateData(dataPoints: days, values: attendanceCount)
    //    populateData(dataPoints,values)
    
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  func setup(chartView: BarChartView) {
    chartView.leftAxis.axisMinimum = 0
    print(weekDataMax)
    chartView.leftAxis.axisMaximum = Double(weekDataMax.1)!
    chartView.leftAxis.axisLineColor = .clear
    chartView.rightAxis.enabled = false
    chartView.drawGridBackgroundEnabled = false
    chartView.drawValueAboveBarEnabled = false
    chartView.xAxis.labelPosition = .bottom
    chartView.xAxis.axisLineColor = .clear
    chartView.fitBars = true
    chartView.chartDescription?.text = ""
    barChart.noDataText = ""
  }
  
  func populateData(dataPoints: [String], values: [Double]) {
    var dataEntries: [BarChartDataEntry] = []
    print(dataPoints.count)
    for i in 0..<dataPoints.count {
      let dataEntry = BarChartDataEntry(x: Double(i), y: values[i])
      dataEntries.append(dataEntry)
    }
    let chartDataSet = BarChartDataSet(values: dataEntries, label: "Attendance count")
    let chartData = BarChartData(dataSet: chartDataSet)
    barChart.data = chartData
    barChart.animate(xAxisDuration: 1.0, yAxisDuration: 1.0)
    barChart.noDataText = ""
    let xAxisValue = barChart.xAxis
//    xAxisValue.valueFormatter = axisFormatDelegate
  }
  
}
//
//extension StatsViewController: IAxisValueFormatter {
//
//  func stringForValue(_ value: Double, axis: AxisBase?) -> String {
//    return months[Int(value)]
//  }
//}
