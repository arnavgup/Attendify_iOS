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
  var months: [String]! = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]

  
  var days: [String]!

  override func viewDidLoad() {
    super.viewDidLoad()
    axisFormatDelegate = self
    self.view.backgroundColor = .white
    barChart.invalidateIntrinsicContentSize()
    let weekOfData = HomeViewController().weekOfData
    days = weekOfData.map { $0.0.components(separatedBy: "-")[1]+"/"+$0.0.components(separatedBy: "-")[2].components(separatedBy: "T")[0] }
    let attendanceCount = weekOfData.map { Double($0.1) }
    averageCard.setTitle(HomeViewController().weekDataAvg, for: .normal)
    todayCard.setTitle(HomeViewController().weekDataToday, for: .normal)
    highestCard.setTitle(HomeViewController().weekDataMax.1, for: .normal)
    lowestCard.setTitle(HomeViewController().weekDataMin.1, for: .normal)
    setup(chartView: barChart)
    populateData(dataPoints: days, values: attendanceCount)
//    populateData(dataPoints,values)
    
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  func setup(chartView: BarChartView) {
    chartView.leftAxis.axisMinimum = 0
    chartView.leftAxis.axisMaximum = Double(HomeViewController().weekDataMax.1)!
    chartView.leftAxis.axisLineColor = .clear
    chartView.rightAxis.enabled = false
    chartView.drawGridBackgroundEnabled = false
    chartView.xAxis.labelPosition = .bottom
    chartView.xAxis.axisLineColor = .clear
    chartView.fitBars = true
    chartView.drawValueAboveBarEnabled = false
    chartView.chartDescription?.text = ""
    barChart.noDataText = ""
  }
  
  func populateData(dataPoints: [String], values: [Double]) {
    var dataEntries: [BarChartDataEntry] = []
    for i in 0..<dataPoints.count {
      let dataEntry = BarChartDataEntry(x: Double(i), y: values[i])
      dataEntries.append(dataEntry)
    }
    let chartDataSet = BarChartDataSet(values: dataEntries, label: "Attendance count")
    let chartData = BarChartData(dataSet: chartDataSet)
    barChart.data = chartData
    barChart.animate(xAxisDuration: 1.0, yAxisDuration: 1.0)
    let xAxisValue = barChart.xAxis
    xAxisValue.valueFormatter = axisFormatDelegate
    barChart.noDataText = ""
  }

}

extension StatsViewController: IAxisValueFormatter {
  
  func stringForValue(_ value: Double, axis: AxisBase?) -> String {
    return months[Int(value)]
  }
}
