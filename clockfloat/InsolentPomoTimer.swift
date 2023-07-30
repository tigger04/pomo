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

class InsolentPomoTimer: NSObject, NSApplicationDelegate {
   
   var startTime : Date
   var endTime : Date
   let timerMins : Double = 40
   let graceMins : Double = 5
   let tickSecondsGracePeriod : Double = 4.0
   let tickSecondsOvertimePeriod : Double = 1.0
   let adjustMinsDisplayBySeconds = 15
   
   let fgAlpha = 0.5
   
   let tickIndicatorsGoodPrefix : [String] = [ "🟢", "🔵",  "🟣", "🟡", "🟠" ]
   let tickIndicatorsGoodSuffix : [String] = []
   let tickIndicatorsGracePrefix : [String] = [ "⚠️", "✋", "🙉" ]
   let tickIndicatorsGraceSuffix : [String] = []
   let tickIndicatorsBadPrefix : [String] = ["🔴", "⭕️", "❌", "🛑" ]
   let tickIndicatorsBadSuffix : [String] = []
   
   enum TimerStatus {
      case good
      case grace
      case overtime
   }
   
   var pomSummaryWindows: [EvasiveWindow]
   var pomTimerDetailWindows: [EvasiveWindow]
   
   var dateFont: String = "White Rabbit"
   var dateFontSize: Double = 0.0075
   
   var timeFont: String = "White Rabbit"
   var timeFontSize: Double = 0.02
   
   var late : Double = 150
   
   override public init() {
      pomSummaryWindows = []
      pomTimerDetailWindows = []
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
//            if let dateWindow = self.dateWindow {
//               dateWindow.close()
//            }
//            if let timeWindow = self.timeWindow {
//               timeWindow.close()
//            }
            self.initializeAllScreens()
         }
   }
   
   func getRemainingTimeAsSeconds() -> TimeInterval {
      
      let remainingSeconds = self.endTime.timeIntervalSince(Date())
      return remainingSeconds
      
   }
   
   func getAdjustedRemainingTimeAsMins() -> Double {
      let remainingSeconds = self.getRemainingTimeAsSeconds()
      let adjustedRemainingTimeAsMins = (remainingSeconds + Double(adjustMinsDisplayBySeconds)) / 60
      print("\(remainingSeconds)s adjusted mins: \(adjustedRemainingTimeAsMins) / \(self.getRemainingTimeAsDate())")
      return adjustedRemainingTimeAsMins
   }
   
   func getRemainingTimeAsDate () -> Date {
      
      let remainingTimeAsDate = Date.init(timeIntervalSince1970: self.getRemainingTimeAsSeconds())
      return remainingTimeAsDate
      
   }

   func remainingTimeAsString(formatter: DateFormatter) -> String {
      
      var displayString = String(Int(floor(abs(self.getAdjustedRemainingTimeAsMins()))))
      
      displayString = displayString.appending(self.getTickerPrefixIndicator())
      
      print("\(displayString)")
      return displayString
   }
   

   
   func getTimerStatus () -> TimerStatus {
      
      let remainSecs = self.getRemainingTimeAsSeconds()
      
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
   
   func getTickerSuffixIndicator() -> String{
      // TODO: Need a more elegant way of handling prefix/suffix without becoming a DRY infidel
      
      var tickArray : Array<String>
      var tickPeriod : Double
      var tickPhase : Double
      var tickIndex : Int
//      var tickSeconds : Double
      let totalS = self.timerMins * 60
      let remainS = round(self.getRemainingTimeAsSeconds())
      let elapsedS = totalS - remainS
      
      switch self.getTimerStatus() {
      case .good:
         tickArray = tickIndicatorsGoodSuffix
         tickPeriod = totalS / Double(tickArray.count) // 2400 / 5 = 480
         tickPhase = elapsedS / tickPeriod
         tickIndex = abs(min(Int(tickPhase), (tickArray.count-1)))
//         print("GOOD: ElapsedS: \(elapsedS), RemainS: \(remainS), Period: \(tickPeriod), Phase: \(tickPhase), Index: \(tickIndex)")
         return tickArray[tickIndex]
      case .grace:
         tickArray = tickIndicatorsGraceSuffix
         tickPeriod = self.tickSecondsGracePeriod
         tickPhase = elapsedS / tickPeriod
         tickIndex = Int(round(tickPhase)) % tickArray.count
//         print("GRACE: ElapsedS: \(elapsedS), RemainS: \(remainS), Period: \(tickPeriod), Phase: \(tickPhase), Index: \(tickIndex)")
         return tickArray[tickIndex]
      case .overtime:
         tickArray = tickIndicatorsBadSuffix
         tickPeriod = self.tickSecondsOvertimePeriod
         tickPhase = elapsedS / tickPeriod
         tickIndex = Int(round(tickPhase)) % tickArray.count
//         print("GRACE: ElapsedS: \(elapsedS), RemainS: \(remainS), Period: \(tickPeriod), Phase: \(tickPhase), Index: \(tickIndex)")
         return tickArray[tickIndex]
      }
   }
   
   func getTickerPrefixIndicator() -> String{
      // TODO: As above, infidel
      
      var tickArray : Array<String>
      var tickPeriod : Double
      var tickPhase : Double
      var tickIndex : Int
//      var tickSeconds : Double
      let totalS = self.timerMins * 60
      let remainS = round(self.getRemainingTimeAsSeconds())
      let elapsedS = totalS - remainS
      
      switch self.getTimerStatus() {
      case .good:
         tickArray = tickIndicatorsGoodPrefix
         tickPeriod = totalS / Double(tickArray.count) // 2400 / 5 = 480
         tickPhase = elapsedS / tickPeriod
         tickIndex = abs(min(Int(tickPhase), (tickArray.count-1)))
//         print("GOOD: ElapsedS: \(elapsedS), RemainS: \(remainS), Period: \(tickPeriod), Phase: \(tickPhase), Index: \(tickIndex)")
         return tickArray[tickIndex]
      case .grace:
         tickArray = tickIndicatorsGracePrefix
         tickPeriod = self.tickSecondsGracePeriod
         tickPhase = elapsedS / tickPeriod
         tickIndex = Int(round(tickPhase)) % tickArray.count
//         print("GRACE: ElapsedS: \(elapsedS), RemainS: \(remainS), Period: \(tickPeriod), Phase: \(tickPhase), Index: \(tickIndex)")
         return tickArray[tickIndex]
      case .overtime:
         tickArray = tickIndicatorsBadPrefix
         tickPeriod = self.tickSecondsOvertimePeriod
         tickPhase = elapsedS / tickPeriod
         tickIndex = Int(round(tickPhase)) % tickArray.count
//         print("GRACE: ElapsedS: \(elapsedS), RemainS: \(remainS), Period: \(tickPeriod), Phase: \(tickPhase), Index: \(tickIndex)")
         return tickArray[tickIndex]
      }
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
      
      label.textColor = NSColor(red: 1, green: 1, blue: 1, alpha: self.fgAlpha)
      //        label.sizeToFit()
      
      if format == "mins" {
         label.timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            label.stringValue = self.remainingTimeAsString(formatter: formatter)
         }
      } else {
         label.timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            label.stringValue = formatter.string(from: self.getRemainingTimeAsDate())
         }
      }
      
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
         format: "mm:ss",
         interval: 1,
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
         format: "mins",
         interval: 1,
         dummytext: "mins"
      )
      
      self.timeWindow = self.initWindow(
         label: label,
         name: "timer",
         screen: screen
      )
   }
}
