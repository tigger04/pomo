//
//  Logger.swift
//  clockfloat
//
//  Created by tigger on 31/07/2023.
//

import Foundation

class Logger : NSObject {
   
   let dateFormat = "yyyy-MM-dd HH:mm:ss"
   var dateFormatter : DateFormatter
   
   override public init() {
      dateFormatter = DateFormatter()
      dateFormatter.dateFormat = self.dateFormat
   }
   
   public func log(_ message : String) {
      let timestampString = dateFormatter.string(from: Date())
      print("[\(timestampString)] \(message)")
   }
}
