//
//
//  Created by Paulo.
//  Copyright (c) 2015 xyz. All rights reserved.
//

import UIKit

@objc protocol CounterDelegate {
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
    // Factory Method
    class func initWithHue(hue: CGFloat) -> Counter {
        let counterTypeInt = arc4random_uniform(UInt32(CounterType.maxCount))
        let namespace = NSBundle.mainBundle().infoDictionary!["CFBundleExecutable"] as! String
        let counterTypeString = namespace + "." + (CounterType(rawValue: Int(counterTypeInt))?.description)!
        let counterSubclass = NSClassFromString(counterTypeString) as! Counter.Type
        
        return counterSubclass.init(hue: hue)
    }
}

class Operation: NSOperation {
    enum State {
        case Ready, Executing, Finished, Cancelled
        func keyPath() -> String {
            switch self {
            case Ready:
                return "isReady"
            case Executing:
                return "isExecuting"
            case Finished:
                return "isFinished"
            case Cancelled:
                return "isCancelled"
            }
        }
    }
    private var state = State.Ready {
        willSet {
            willChangeValueForKey(newValue.keyPath())
            willChangeValueForKey(state.keyPath())
        }
        didSet {
            didChangeValueForKey(oldValue.keyPath())
            didChangeValueForKey(state.keyPath())
        }
    }
    override var ready: Bool {return super.ready && state == .Ready}
    override var executing: Bool {return state == .Executing}
    override var finished: Bool {return state == .Finished}
    override var cancelled: Bool {return state == .Cancelled}
    override var asynchronous: Bool {return true}

    func start(loop: () -> Void) {
        super.start()
        if self.cancelled {
            state = .Finished
        } else {
            state = .Executing
            loop()
        }
    }
    
    func finish() {
        state = .Finished
    }

    override func cancel() {
        super.cancel()
        state = .Cancelled
    }
}

class Counter: UIView {
    lazy var operation = Operation()

    let MAX_COUNT: Int = 100
    let MAX_DELAY_SEC: Double = 5.0
    let MIN_DELAY_SEC: Double = 0.0
    
    let lblCounting: UILabel = UILabel(frame: CGRectZero)
    let progCounting: UIProgressView = UIProgressView(frame: CGRectZero)
    
    private var delaySecOffset: Double = 0.0
    private var delaySecWithOffset: Double = 0.0
    var delaySec: Double = 0.0 {
        didSet {
            delaySecWithOffset = delaySec + delaySecOffset
        }
    }
    var brightness: CGFloat = 0.6
    var hue: CGFloat
    var delegate: CounterDelegate?
    var speed: Double = 0.0 {
        willSet {
            if newValue >= MIN_DELAY_SEC && newValue <= MAX_DELAY_SEC  {
                delaySecWithOffset += newValue - speed
                brightness -= CGFloat(newValue - speed) / 10.0
                backgroundColor = CounterType.colorWithHue(hue, brightness: brightness)
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
        lblCounting.translatesAutoresizingMaskIntoConstraints = false
        progCounting.translatesAutoresizingMaskIntoConstraints = false
        lblCounting.textColor = UIColor.whiteColor()
        lblCounting.textAlignment = NSTextAlignment.Center
        lblCounting.baselineAdjustment = UIBaselineAdjustment.AlignCenters
        lblCounting.adjustsFontSizeToFitWidth = true
        lblCounting.minimumScaleFactor = 0.05
        lblCounting.font = UIFont(name: "Helvetica", size: 400)
        lblCounting.text = "0"
        progCounting.progressViewStyle = .Bar
        let huePlus180Degrees = hue + 0.5 > 1.0 ? hue + 0.5 - 1.0 : hue + 0.5
        progCounting.progressTintColor = UIColor(hue: huePlus180Degrees, saturation: 0.8, brightness: 1.0, alpha: 0.2)
        self.backgroundColor = CounterType.colorWithHue(hue, brightness: brightness)
        self.addSubview(lblCounting)
        self.addSubview(progCounting)
        delaySecOffset = slowDownRandomSec()
        running()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        // Setting lblCounting autolayout constraints
        self.addConstraint(NSLayoutConstraint(item: lblCounting, attribute: .Width, relatedBy: .Equal, toItem: self, attribute: .Width, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: lblCounting, attribute: .Height, relatedBy: .Equal, toItem: self, attribute: .Height, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: lblCounting, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: lblCounting, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1, constant: 0))
        
        // Setting progCounting autolayout constraints
        self.addConstraint(NSLayoutConstraint(item: progCounting, attribute: .Width, relatedBy: .Equal, toItem: self, attribute: .Width, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: progCounting, attribute: .Height, relatedBy: .Equal, toItem: self, attribute: .Height, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: progCounting, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: progCounting, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1, constant: 0))
        
        super.updateConstraints()
    }
    
    private func running() {
        operation.start({
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                for i in 1...self.MAX_COUNT {
                    if self.operation.cancelled {break}
                    NSThread.sleepForTimeInterval(self.delaySecWithOffset)
                    dispatch_sync(dispatch_get_main_queue(), {
                        self.lblCounting.text = String(i)
                        self.progCounting.progress = Float(i) / Float(self.MAX_COUNT)
                    })
                }
                dispatch_sync(dispatch_get_main_queue(), {
                    self.operation.finish()
                    guard let newEndText = self.delegate!.setCounterTextAfterCountingEnd?() else {
                        return
                    }
                    self.lblCounting.text = newEndText
                })
            })
        })
    }
    
    override func removeFromSuperview() {
        operation.cancel()
        super.removeFromSuperview()
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