//
//
//  Created by Paulo.
//  Copyright (c) 2015 xyz. All rights reserved.
//

import UIKit

@objc protocol CounterDelegate {
    optional func didFinishCounting(counter: Counter)
    optional func setCounterTextAfterCountingEnd() -> String
}

// - Based on Nate Cook's web site ideas -
extension CounterType: CustomStringConvertible {
    var description: String {
        let counterType = ["Fast", "Average", "Slow"]
        return counterType[self.rawValue] + "Counter"
    }
}
// - - -

enum CounterType: Int {
    case Fast, Average, Slow

    // - Based on Nate Cook's web site ideas -
    static var maxCount: Int {
        var numOfCounters: Int = 0
        while let _ = self.init(rawValue: ++numOfCounters) {}
        return numOfCounters
    }
    // - - -
    
    static func colorWithHue(hue: CGFloat, brightness: CGFloat) -> UIColor {
        return UIColor(hue: hue, saturation: 0.8, brightness: brightness, alpha: 1.0)
    }
}

class CounterFactory {
    private static var counterNumber: Int = 0
    
    // Factory Method
    class func initWithHue(hue: CGFloat) -> Counter {
        let counterTypeInt = arc4random_uniform(UInt32(CounterType.maxCount))
        let namespace = NSBundle.mainBundle().infoDictionary!["CFBundleExecutable"] as! String
        let counterTypeString = namespace + "." + (CounterType(rawValue: Int(counterTypeInt))?.description)!
        let counterSubclass = NSClassFromString(counterTypeString) as! Counter.Type
        
        let counter = counterSubclass.init(hue: hue)
        counter.tag = ++counterNumber
        return counter
    }
}

class Counter: UILabel {
    internal let MAX_COUNT: Int = 100
    internal let MAX_DELAY_SEC: Double = 5.0
    internal let MIN_DELAY_SEC: Double = 0.0
    
    private var delaySecOffset: Double = 0.0
    private var delaySecWithOffset: Double = 0.0
    internal var delaySec: Double = 0.0 {
        didSet {
            delaySecWithOffset = delaySec + delaySecOffset
        }
    }
    internal var brightness: CGFloat = 0.6
    internal var hue: CGFloat
    var delegate: CounterDelegate?
    var speed: Double = 0.0 {
        willSet {
            if newValue >= MIN_DELAY_SEC && newValue <= MAX_DELAY_SEC  {
                delaySecWithOffset += newValue - speed
                brightness -= CGFloat(newValue - speed) / 10.0
                self.backgroundColor = CounterType.colorWithHue(hue, brightness: brightness)
            }
        }
        didSet {
            if speed < MIN_DELAY_SEC {
                speed = MIN_DELAY_SEC
                delaySecWithOffset = delaySec + delaySecOffset + MIN_DELAY_SEC
            }
            else if speed > MAX_DELAY_SEC {
                speed = MAX_DELAY_SEC
                delaySecWithOffset = delaySec + delaySecOffset + MAX_DELAY_SEC
            }
        }
    }
    
    required init(hue: CGFloat) {
        self.hue = hue
        super.init(frame: CGRectZero)
        self.textColor = UIColor.whiteColor()
        self.textAlignment = NSTextAlignment.Center
        self.baselineAdjustment = UIBaselineAdjustment.AlignCenters
        self.adjustsFontSizeToFitWidth = true
        self.minimumScaleFactor = 0.05
        self.font = UIFont(name: "Helvetica", size: 400)
        self.text = "0"
        self.backgroundColor = CounterType.colorWithHue(hue, brightness: brightness)
        delaySecOffset = slowDownRandomSec()
        self.running()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    internal func running() -> () {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            for i in 1...self.MAX_COUNT {
                NSThread.sleepForTimeInterval(self.delaySecWithOffset)
                dispatch_sync(dispatch_get_main_queue(), {
                    self.text = String(i)
                })
            }
            dispatch_sync(dispatch_get_main_queue(), {
                self.delegate!.didFinishCounting!(self)
                guard let newEndText = self.delegate!.setCounterTextAfterCountingEnd?() else {
                    return
                }
                self.text = newEndText
            })
        })
    }
    
    private func slowDownRandomSec() -> Double {
        return Double(arc4random_uniform(10)) / 100
    }
}

// MARK: - Counter class subtypes declarations
class FastCounter: Counter {
    required init(hue: CGFloat) {
        super.init(hue: hue)
        brightness = 0.6
        self.backgroundColor = CounterType.colorWithHue(hue, brightness: brightness)
        delaySec = 0.0
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class AverageCounter: Counter {
    required init(hue: CGFloat) {
        super.init(hue: hue)
        brightness = 0.8
        self.backgroundColor = CounterType.colorWithHue(hue, brightness: brightness)
        delaySec = 0.1
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SlowCounter: Counter {
    required init(hue: CGFloat) {
        super.init(hue: hue)
        brightness = 1.0
        self.backgroundColor = CounterType.colorWithHue(hue, brightness: brightness)
        delaySec = 0.2
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}