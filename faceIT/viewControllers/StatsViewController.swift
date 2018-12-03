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
  @IBOutlet weak var averageCardMetric: UILabel!
  @IBOutlet weak var todayCardMetric: UILabel!
  @IBOutlet weak var highestCardMetric: UILabel!
  @IBOutlet weak var lowestCardMetric: UILabel!
  @IBOutlet weak var changeMetric: UIButton!
    @IBOutlet weak var showButton:UIButton!
    @IBOutlet weak var returnButton:UIButton!
  @IBOutlet weak var barChart: BarChartView!
  weak var axisFormatDelegate: IAxisValueFormatter?
  let yformatter = NumberFormatter()
  
  
  var state: Bool = false
  var days: [String]!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    axisFormatDelegate = self
    self.showButton.layer.cornerRadius = 10
    self.showButton.layer.masksToBounds = true
    self.returnButton.layer.cornerRadius = 10
    self.returnButton.layer.masksToBounds = true
    self.view.backgroundColor = UIColor.white
    self.barChart.invalidateIntrinsicContentSize()
    let weekData = weekOfData
    days = weekData.map { $0.0.components(separatedBy: "-")[1]+"/"+$0.0.components(separatedBy: "-")[2].components(separatedBy: "T")[0] }
    let x = days
    days = x?.sorted()
    let attendanceCount = weekData.sorted(by: { $0.0 < $1.0 }).map( { Double($0.1) })
    print("CHECK HERE!!!")
    print(days)
    print(attendanceCount)
    averageCard.setTitle(weekDataAvg, for: .normal)
    averageCardMetric.text = "Students"
    todayCard.setTitle(weekDataToday, for: .normal)
    todayCardMetric.text = "Students"
    highestCard.setTitle(weekDataMax.1, for: .normal)
    highestCardMetric.text = "Students"
    lowestCard.setTitle(weekDataMin.1, for: .normal)
    lowestCardMetric.text = "Students"
    populateData(dataPoints: days, values: attendanceCount)
    setup(chartView: barChart)
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  func setup(chartView: BarChartView) {
    chartView.leftAxis.axisMinimum = 0
    chartView.leftAxis.axisMaximum = Double(weekDataMax.1)!
    chartView.leftAxis.axisLineColor = .clear
    chartView.leftAxis.granularity = 1
    chartView.rightAxis.enabled = false
    chartView.drawGridBackgroundEnabled = false
    chartView.drawValueAboveBarEnabled = false
    chartView.xAxis.labelPosition = .bottom
    chartView.xAxis.axisLineColor = .clear
    chartView.xAxis.granularity = 1
    chartView.fitBars = true
    chartView.chartDescription?.text = ""
    chartView.backgroundColor = UIColor.white
    chartView.animate(xAxisDuration: 1.0, yAxisDuration: 1.0)
    chartView.xAxis.valueFormatter = axisFormatDelegate
  }
  
  func populateData(dataPoints: [String], values: [Double]) {
    var dataEntries: [BarChartDataEntry] = []
    for i in 0..<dataPoints.count {
      let dataEntry = BarChartDataEntry(x: Double(i), y: values[i])
      dataEntries.append(dataEntry)
    }
    let chartDataSet = BarChartDataSet(values: dataEntries, label: "Attendance count")
    chartDataSet.colors = [UIColor(red: 0, green: 255, blue: 255, alpha: 1)]
    let chartData = BarChartData(dataSet: chartDataSet)
    yformatter.minimumFractionDigits = 0
    chartData.setValueFormatter(DefaultValueFormatter(formatter: yformatter))
    barChart.data = chartData
    barChart.data?.setDrawValues(false)
  }
  
  
  
  @IBAction func switchDataMetric(_ sender: AnyObject) {
    state = !state
    if (state) {
      // Show percentage
      let averageData = (Double(weekDataAvg)!/Double(todayAttendance.count)) * 100.00
      let todayData = (Double(weekDataToday)!/Double(todayAttendance.count)) * 100.00
      let maxData = (Double(weekDataMax.1)!/Double(todayAttendance.count)) * 100.00
      let minData = (Double(weekDataMin.1)!/Double(todayAttendance.count)) * 100.00
      if (!averageData.isNaN) {
        averageCard.setTitle(String(format:"%.1f",averageData), for: .normal)
      } else {
        averageCard.setTitle("0.0", for: .normal)
      }
      if (!todayData.isNaN) {
        todayCard.setTitle(String(format:"%.1f",todayData), for: .normal)
      } else {
        todayCard.setTitle("0.0", for: .normal)
      }
      if (!maxData.isNaN) {
        highestCard.setTitle(String(format:"%.1f",maxData), for: .normal)
      } else {
        highestCard.setTitle("0.0", for: .normal)
      }
      if (!minData.isNaN) {
        lowestCard.setTitle(String(format:"%.1f",minData), for: .normal)
      } else {
        lowestCard.setTitle("0.0", for: .normal)
      }
      averageCardMetric.text = "%"
      todayCardMetric.text = "%"
      highestCardMetric.text = "%"
      lowestCardMetric.text = "%"
      changeMetric.setTitle("Switch to count", for: .normal)
      self.view.makeToast("Switched to percentage", duration: 0.5, position: .center)
    } else {
      // Show count
      averageCard.setTitle(weekDataAvg, for: .normal)
      averageCardMetric.text = "Students"
      todayCard.setTitle(weekDataToday, for: .normal)
      todayCardMetric.text = "Students"
      highestCard.setTitle(weekDataMax.1, for: .normal)
      highestCardMetric.text = "Students"
      lowestCard.setTitle(weekDataMin.1, for: .normal)
      lowestCardMetric.text = "Students"
      changeMetric.setTitle("Switch to %", for: .normal)
      self.view.makeToast("Switched to count", duration: 0.5, position: .center)
    }
    
  }

}
extension StatsViewController: IAxisValueFormatter {

  func stringForValue(_ value: Double, axis: AxisBase?) -> String {
    let weekData = weekOfData
    days = weekData.map { $0.0.components(separatedBy: "-")[1]+"/"+$0.0.components(separatedBy: "-")[2].components(separatedBy: "T")[0] }
    let x = days
    days = x?.sorted()
    return days[Int(value)]
  }
}


