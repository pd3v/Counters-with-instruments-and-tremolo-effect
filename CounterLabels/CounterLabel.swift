//
//  AnimalLable.swift
//  Animals
//
//  Created by Paulo on 16/08/14.
//  Copyright (c) 2014 xyz. All rights reserved.
//

import UIKit

protocol StateDelegate {
    func runDidEnd(counter: CounterLabel)
    func messageAfterEnding() -> String?
}

class CounterLabel: UILabel {
    /*
    enum color: UIColor? {
        case fast = UIColor(hue: 0.10, saturation: 0.80, brightness: 0.99, alpha: 1)
        case average = UIColor(hue: 0.10, saturation: 0.80, brightness: 0.99, alpha: 1)
        case slow = UIColor(hue: 0.10, saturation: 0.80, brightness: 0.99, alpha: 1)
    }
    */

    internal let MAX_COUNT: Int = 1000
    internal let MAX_DELAY_SEC: Double = 5.0
    internal let MIN_DELAY_SEC: Double = 0.0
    
    private var delaySecOffset: Double = 0.0
    internal var delaySecWithOffset: Double = 0.0
    internal var delaySec: Double = 0.0
    
    internal var brightness: CGFloat = 0.6
    internal var hue: CGFloat
    
    var delegate: StateDelegate?
    
    var speedChanged: Double = 0.0 {
        willSet {
            //print("newValue:\(newValue) speedChanged:\(speedChanged) delaySecWithOffset:\(delaySecWithOffset) >0:\(speedChanged > 0) <5:\(speedChanged < 5)" )
            print("Antes delaySecWithOffset:\(delaySecWithOffset)")
            if newValue >= MIN_DELAY_SEC && newValue <= MAX_DELAY_SEC  {
                delaySecWithOffset += newValue - speedChanged
                brightness -= CGFloat(newValue - speedChanged) / 10.0
                self.backgroundColor = UIColor(hue: hue, saturation: 0.8, brightness: brightness, alpha: 1)
                //print("Depois com newValue:\(newValue)  speedChanged:\(speedChanged) delaySecWithOffset:\(delaySecWithOffset) dif:\(newValue - speedChanged)")
                print("Depois delaySecWithOffset:\(delaySecWithOffset)")
            }
        }
        didSet {
            if speedChanged < MIN_DELAY_SEC {
                speedChanged = MIN_DELAY_SEC
                delaySecWithOffset = delaySec + delaySecOffset + MIN_DELAY_SEC
            }
            else if speedChanged > MAX_DELAY_SEC {
                speedChanged = MAX_DELAY_SEC
                delaySecWithOffset = delaySec + delaySecOffset + MAX_DELAY_SEC
            }
            print("self:", self.dynamicType, self.tag, ":", delaySecOffset, delaySecWithOffset)
        }
    }
    
    static var firstCounter = false
    
    init(hue: CGFloat) {
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
        self.backgroundColor = UIColor(hue: hue, saturation: 0.8, brightness: brightness, alpha: 1)
        delaySecOffset = slowDownRandomSec()
        delaySecWithOffset = delaySec + delaySecOffset
        print(delaySecWithOffset)
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
                self.text = self.delegate!.messageAfterEnding() ?? String(self.MAX_COUNT)
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
class FastLabel: CounterLabel {
    override init(hue: CGFloat) {
        super.init(hue: hue)
        brightness = 0.39
        self.backgroundColor = UIColor(hue: hue, saturation: 0.80, brightness: brightness, alpha: 1)
        delaySec = 0.0
        delaySecWithOffset = delaySec + delaySecOffset
        print(delaySecWithOffset)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class AverageLabel: CounterLabel {
    override init(hue: CGFloat) {
        super.init(hue: hue)
        brightness = 0.69
        self.backgroundColor = UIColor(hue: hue, saturation: 0.80, brightness: brightness, alpha: 1)
        delaySec = 0.1
        delaySecWithOffset = delaySec + delaySecOffset
        print(delaySecWithOffset)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SlowLabel: CounterLabel {
    override init(hue: CGFloat) {
        super.init(hue: hue)
        brightness = 0.99
        self.backgroundColor = UIColor(hue: hue, saturation: 0.80, brightness: brightness, alpha: 1)
        delaySec = 0.2
        delaySecWithOffset = delaySec + delaySecOffset
        print(delaySecWithOffset)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}