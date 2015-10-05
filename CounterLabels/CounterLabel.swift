//
//  AnimalLable.swift
//  Animals
//
//  Created by Paulo on 16/08/14.
//  Copyright (c) 2014 xyz. All rights reserved.
//

import UIKit

protocol CounterDelegate {
    func runDidEnd(counter: Counter)
    func textAfterEnding() -> String?
}

// - Based on Nate Cook's blog ideas -
extension CounterType: CustomStringConvertible {
    var description: String {
        let counterType = ["Fast", "Average", "Slow"]
        return counterType[self.rawValue] + "Counter"
    }
}
// - - -

enum CounterType: Int {
    case Fast, Average, Slow

    // - Based on Nate Cook's blog ideas -
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
    
    class func initWithHue(hue: CGFloat) -> Counter {
        let counterTypeInt = arc4random_uniform(UInt32(CounterType.maxCount))
        let namespace = NSBundle.mainBundle().infoDictionary!["CFBundleExecutable"] as! String
        let counterTypeString = namespace + "." + (CounterType(rawValue: Int(counterTypeInt))?.description)!
        let counterSubclass = NSClassFromString(counterTypeString) as! Counter.Type
        
        return counterSubclass.init(hue: hue)
        
        /*
        class MyClass {
            required init() { print("Hi!") }
        }
        
        if let classObject = NSClassFromString("YOURAPPNAME.MyClass") as? MyClass.Type {
            let object = classObject.init()
        }*/
        
        /*
        switch counterType {
        case 1:
            return FastLabel(hue: hue)
        case 2:
            return AverageLabel(hue: hue)
        case 3:
            return SlowLabel(hue: hue)
        default:
            return SlowLabel(hue: hue)
        }*/
        
        
    }
}

class Counter: UILabel {

    internal let MAX_COUNT: Int = 1000
    internal let MAX_DELAY_SEC: Double = 5.0
    internal let MIN_DELAY_SEC: Double = 0.0
    
    private var delaySecOffset: Double = 0.0
    private var delaySecWithOffset: Double = 0.0
    internal var delaySec: Double = 0.0 {
        didSet {
            delaySecWithOffset = delaySec + delaySecOffset
            //print("didSet:\(delaySec) + \(delaySecOffset) = \(delaySecWithOffset)")
        }
    }
    
    internal var brightness: CGFloat = 0.6
    internal var hue: CGFloat
    
    var delegate: CounterDelegate?
    
    var speed: Double = 0.0 {
        willSet {
            //print("newValue:\(newValue) speedChanged:\(speedChanged) delaySecWithOffset:\(delaySecWithOffset) >0:\(speedChanged > 0) <5:\(speedChanged < 5)" )
            //print("Antes delaySecWithOffset:\(delaySecWithOffset)")
            if newValue >= MIN_DELAY_SEC && newValue <= MAX_DELAY_SEC  {
                delaySecWithOffset += newValue - speed
                brightness -= CGFloat(newValue - speed) / 10.0
                self.backgroundColor = CounterType.colorWithHue(hue, brightness: brightness) //UIColor(hue: hue, saturation: 0.8, brightness: brightness, alpha: 1)
                //print("Depois com newValue:\(newValue)  speedChanged:\(speedChanged) delaySecWithOffset:\(delaySecWithOffset) dif:\(newValue - speedChanged)")
                //print("Depois delaySecWithOffset:\(delaySecWithOffset)")
                print(brightness - CGFloat(newValue - speed), brightness)
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
            //print("self:", self.dynamicType, self.tag, ":", delaySecOffset, delaySecWithOffset)
        }
    }
    
    static var firstCounter = false
    
    required init(hue: CGFloat) {
        self.hue = hue
        super.init(frame: CGRectZero)
        self.textColor = UIColor.whiteColor()
        self.textAlignment = NSTextAlignment.Center
        self.baselineAdjustment = UIBaselineAdjustment.AlignCenters
        self.adjustsFontSizeToFitWidth = true
        //self.numberOfLines = 1
        self.minimumScaleFactor = 0.05
        self.font = UIFont(name: "Helvetica", size: 400)
        self.text = "0"
        self.backgroundColor = CounterType.colorWithHue(hue, brightness: brightness) //UIColor(hue: hue, saturation: 0.8, brightness: brightness, alpha: 1)
        delaySecOffset = slowDownRandomSec()
        /*delaySecWithOffset = delaySec + delaySecOffset
        print(delaySecWithOffset)*/
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
            // Not in use for now
            dispatch_sync(dispatch_get_main_queue(), {
                //self.delegate!.runDidEnd(self)
                self.text = self.delegate!.textAfterEnding() ?? String(self.MAX_COUNT)
            })
        })
    }
    
    private func slowDownRandomSec() -> Double {
        return Double(arc4random_uniform(10)) / 100
    }
    
    /*
    private func roundToN(places places: Double, num: Double) -> Double {
        //let numberOfPlaces = 4.0
        let multiplier = pow(10.0, places)
        let rounded = round(num * multiplier) / multiplier
        print(num, rounded)
        return rounded
    }
    */
}

// MARK: - CounterLabel Subtypes Declarations
class FastCounter: Counter {
    required init(hue: CGFloat) {
        super.init(hue: hue)
        brightness = 0.6
        self.backgroundColor = CounterType.colorWithHue(hue, brightness: brightness) //UIColor(hue: hue, saturation: 0.80, brightness: brightness, alpha: 1)
        delaySec = 0.0
        //delaySecWithOffset = delaySec + delaySecOffset
        //print(delaySecWithOffset)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class AverageCounter: Counter {
    required init(hue: CGFloat) {
        super.init(hue: hue)
        brightness = 0.8
        self.backgroundColor = CounterType.colorWithHue(hue, brightness: brightness) //UIColor(hue: hue, saturation: 0.80, brightness: brightness, alpha: 1)
        delaySec = 0.1
        //delaySecWithOffset = delaySec + delaySecOffset
        //print(delaySecWithOffset)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SlowCounter: Counter {
    required init(hue: CGFloat) {
        super.init(hue: hue)
        brightness = 1.0
        self.backgroundColor = CounterType.colorWithHue(hue, brightness: brightness) //UIColor(hue: hue, saturation: 0.80, brightness: brightness, alpha: 1)
        delaySec = 0.2
        //delaySecWithOffset = delaySec + delaySecOffset
        //print(delaySecWithOffset)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}