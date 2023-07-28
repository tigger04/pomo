// The MIT License

// Copyright (c) 2023 Tadhg O'Brien

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Cocoa

class Clock: NSObject, NSApplicationDelegate {
   
   var startTime : Date
   var endTime : Date
   let timerMins : Int = 40
   let graceMins : Int = 5
   let tickIndicatorsGood : [String] = [ "🟢", "🔵",  "🟣", "🟡", "🟠" ]
   let tickIndicatorsGrace : [String] = [ "⚠️", "⛔️", "🙉" ]
   let tickIndicatorsBad : [String] = ["🔴", "⭕️", "❌", "🛑", "✋" ]
   
   enum TimerStatus {
      case good
      case grace
      case overtime
   }

   var dateWindow: EvasiveWindow?
   var timeWindow: EvasiveWindow?

   var dateFont: String = "White Rabbit"
   var dateFontSize: Double = 0.01

   var timeFont: String = "White Rabbit"
   var timeFontSize: Double = 0.03

   var late : Double = 150
   
   override public init() {
      self.startTime = Date()
      self.endTime = self.startTime.addingTimeInterval(TimeInterval(timerMins * 60))
      super.init()
   }

   func applicationDidFinishLaunching(_ aNotification: Notification) {
      self.initializeAllScreens()
      self.watchForScreenChanges()
   }

   func initializeAllScreens() {

      for screen in NSScreen.screens {
         self.initTimer(screen: screen)
         self.initDater(screen: screen)
      }
   }

   func watchForScreenChanges() {
      NotificationCenter.default.addObserver(
         forName: NSNotification.Name(rawValue: "NSApplicationDidChangeScreenParametersNotification"),
         object: NSApplication.shared,
         queue: .main) { notification in
            if let dateWindow = self.dateWindow {
               dateWindow.close()
            }
            if let timeWindow = self.timeWindow {
               timeWindow.close()
            }
            self.initializeAllScreens()
         }
   }
   
   func getRemainingTimeAsSeconds() -> TimeInterval {
      
      let remainingSeconds = self.endTime.timeIntervalSince(Date())
      return remainingSeconds
      
   }

   func getRemainingTimeAsDate () -> Date {
      
      return Date.init(timeIntervalSince1970: self.getRemainingTimeAsSeconds())
      
   }
   
   func getTimerStatus () -> TimerStatus {
      
      var remainSecs = self.getRemainingTimeAsSeconds()
      
      var timerStatus: TimerStatus
      
      switch remainSecs {
      case let x where x > 0:
         timerStatus = .good
      case let x where x > Double(-1 * (60 * self.graceMins)):
         timerStatus = .grace
      default:
         timerStatus = .overtime
      }
      
      return timerStatus
      
   }
   
   func getTickerIndicator() -> String{
   
      var tickArray : Array<String>
      var tickIndex : Int
      
      switch self.getTimerStatus() {
      case .good:
         tickArray = tickIndicatorsGood
         let tickPeriod = self.timerMins * 60 / tickArray.count // 2400 / 5 = 480
         let tickPhase = self.getRemainingTimeAsSeconds() / Double(tickPeriod)
         // 2400/480=5, 2399/480=4.99, 1200/480= 2.5, 300/480=0.625, 1/480=0.002
         tickIndex = Int(round(tickPhase - 1))
//         return tickIndicatorsGood[tickIndex]
      case .grace:
         tickArray = tickIndicatorsGrace
         tickPeriod = 1.0
      case .overtime:
         tickArray = tickIndicatorsBad
         tickPeriod = 1.0
      }
      
      return tickArray[tickIndex]
      
      let tickIndex = tickIndicatorsGood.count - (Int(self.getRemainingTimeAsSeconds()) % tickIndicatorsGood.count) - 1
      return self.tickIndicatorsGood[tickIndex]
      
   }

   func remainingTimeAsString(formatter: DateFormatter) -> String {
      
      var displayString = formatter.string(from: self.getRemainingTimeAsDate())
      
      displayString = displayString.appending(self.getTickerIndicator())
      
      return displayString
   }

   func initLabel(font: String, fontHeight: Double, screen: NSScreen, format: String, interval: TimeInterval, dummytext: String) -> TickingTextField {

      let formatter = DateFormatter()
      formatter.dateFormat = format

//      let tmpLabel = NSTextField()
//      tmpLabel.font = NSFont(name: font, size: 20)
//      tmpLabel.isBezeled = false
//      tmpLabel.isEditable = false
//      tmpLabel.drawsBackground = false
//      tmpLabel.alignment = .center
//      tmpLabel.stringValue = dummytext

      let pixelsPerPoint = NSFont(name: font, size: 20)!.boundingRectForFont.height / 20.0
//      let tmpLabelHeight = tmpLabel.frame.height
//      let pixelsPerPoint = Double(tmpLabelHeight) / 20.0

      let label = TickingTextField()

      if fontHeight < 1.0 {
         let resolvedFontSize = screen.frame.height * fontHeight / pixelsPerPoint
         label.font = NSFont(name: font, size: resolvedFontSize)
      }
      else {
         label.font = NSFont(name: font, size: fontHeight)
      }

      label.isBezeled = false
      label.isEditable = false
      label.drawsBackground = false
      label.alignment = .center
      label.stringValue = dummytext

      label.textColor = NSColor(red: 1, green: 1, blue: 1, alpha: 0.5)
//        label.sizeToFit()

      label.timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
         label.stringValue = self.remainingTimeAsString(formatter: formatter)
//         label.stringValue = String(Int(self.endTime.timeIntervalSince(self.startTime)))
      }
//      label.timer!.tolerance = interval / 10
      label.timer!.fire()

      return label
   }

   func initWindow(label: TickingTextField, name: String, screen: NSScreen, stickWin: EvasiveWindow? = nil) -> EvasiveWindow {
      let window = EvasiveWindow(label: label, name: name, screen: screen, stickWin: stickWin)

      return window
   }

   func initDater(screen: NSScreen) {
//      if self.dateFontSize < 1.0 {
//         self.dateFontSize = self.dateFontSize * screen.frame.height
//      }

      let label = self.initLabel(
         font: self.dateFont,
         fontHeight: self.dateFontSize,
         screen: screen,
         format: "d/M/YYYY HH:mm:ss",
         interval: 5,
         dummytext: "mm:ss"
      )

      self.dateWindow = self.initWindow(
         label: label,
         name: "dater",
         screen: screen,
         stickWin: self.timeWindow!
      )
   }

   func initTimer(screen: NSScreen) {
      let label = self.initLabel(
         font: self.timeFont,
         fontHeight: self.timeFontSize,
         screen: screen,
         format: "   mm:ss   ",
         interval: 1,
         dummytext: "mm"
      )

      self.timeWindow = self.initWindow(
         label: label,
         name: "timer",
         screen: screen
      )
   }
}
