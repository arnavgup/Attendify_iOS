//
//  BarChartFormatter.swift
//  faceIT
//
//  Created by George Yao on 11/29/18.
//  Copyright © 2018 NovaTec GmbH. All rights reserved.
//

import UIKit
import Foundation
import Charts

@objc(BarChartFormatter)
public class BarChartFormatter: NSObject, IAxisValueFormatter{
  
  var months: [String]! = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
  
  
  public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
    
    return months[Int(value)]
    
  }
}
