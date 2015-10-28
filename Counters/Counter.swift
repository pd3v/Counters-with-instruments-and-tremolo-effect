//
//
//  Created by Paulo.
//  Copyright (c) 2015 xyz. All rights reserved.
//

import UIKit

@objc protocol CounterDelegate {
    optional func setCounterTextAfterCountingEnd() -> String
}

/*extension UIProgressView {
    override public func sizeThatFits(size: CGSize) -> CGSize {
        let newSize = CGSizeMake(10, self.frame.height)
        return newSize
    }
}*/

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

/*class Counter: UILabel {
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
}*/

class Timer: NSOperation {

    /*let maxCount: Int?
    let lblC: UILabel?
    let progC: UIProgressView?
    var delaySec: Double? {
        willSet{
            print(newValue)
        }
        didSet{
            print("Did set delaySec:\(delaySec)")
        }
    }*/
    
    static var num = 0
    
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
    
    var state = State.Ready {
        willSet {
            willChangeValueForKey(newValue.keyPath())
            willChangeValueForKey(state.keyPath())
        }
        didSet {
            didChangeValueForKey(oldValue.keyPath())
            didChangeValueForKey(state.keyPath())
        }
    }
    
    override var ready: Bool {
        return super.ready && state == .Ready
    }
    
    override var executing: Bool {
        return state == .Executing
    }
    
    override var finished: Bool {
        print("\(self.name) finished")
        return state == .Finished
    }
    
    override var cancelled: Bool {
        //print("\(self.name) -> isCancelled Total:\(total)")
        //print(cancelled)
        return state == .Cancelled
    }
    
    override var asynchronous: Bool {
        return true
    }

    override init(/*maxCount: Int, lblC: UILabel, progC: UIProgressView, delaySec: Double*/) {
        /*self.maxCount = maxCount
        self.lblC = lblC
        self.progC = progC
        self.delaySec = delaySec*/
        //state == .Ready
        super.init()
        self.name = "Op" + String(++Timer.num)
        //print("\(self.name!) is ready:Go!")
    }
    
    /*override func start() {
        if self.cancelled {
            //print("cancelled:\(cancelled)")
            state = .Finished
        }
        else {
            state = .Executing
            //print("executing:\(executing)")
            go()
            //self.performSelectorInBackground("go", withObject: nil)
            //print("Is Async?:\(asynchronous)")
        }
    }*/
    
    func start(completion: ()->()) {
        super.start()
        if self.cancelled {
            //print("cancelled:\(cancelled)")
            state = .Finished
        }
        else {
            state = .Executing
            //print("executing:\(executing)")
            go(completion)
            //self.performSelectorInBackground("go", withObject: nil)
            //print("Is Async?:\(asynchronous)")
        }
        //super.start()
    }

    
    override func cancel() {
        //print(__FUNCTION__, self.name!)
        super.cancel()
        //state = .Finished
        state = .Cancelled
    }
    
    func go() {
        // --- Algorithm #1 ---
        /*var l = true
        while l {
            print("Oi!")
            if self.cancelled {
                print("Cancelled!")
                l = !l
            }
        }
        self.state = .Finished
        print("finished:\(self.finished) \(self.total)")
        print("executing:\(self.executing)")*/
        
        // --- Algorithm #2 ---
        /*var dicC: [String: AnyObject] = ["lblC": lblC!, "progC": progC!]
        for i in 1...maxCount! {
            //NSThread.sleepForTimeInterval(self.delaySecWithOffset)
            dicC["i"] = NSNumber(integer: i)
            self.performSelectorOnMainThread("display:", withObject: dicC, waitUntilDone: false)
        }*/
        
        //--- Algorithm #3 ---
        /*
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            print("delaySec in NSOperation loop:\(self.delaySec!)")
            for i in 1...self.maxCount! {
                if self.cancelled {break}
                NSThread.sleepForTimeInterval(self.delaySec!)
                dispatch_sync(dispatch_get_main_queue(), {
                    self.lblC?.text = String(i)
                    self.progC?.progress = Float(i) / Float(self.maxCount!)
                })
            }
            self.state = .Finished
            /*dispatch_sync(dispatch_get_main_queue(), {
                guard let newEndText = self.delegate!.setCounterTextAfterCountingEnd?() else {
                    return
                }
                self.lblCounting.text = newEndText
            })*/
        })
        */

    }
    
    func go(completion: ()->Void) {
        completion()
        self.state = .Finished
    }

    /*func display(v: [String: AnyObject]) {
        (v["lblC"] as! UILabel).text = v["i"]!.stringValue
        (v["progC"] as! UIProgressView).progress = Float(v["i"]!.integerValue) / Float(self.maxCount!)
    }*/
}

class Counter: UIView {
    
    //TODO: Dependy injection: "Your thing should not create create the things it needs."
    // Try to create NSOperation with dependency injection
    lazy var timering: Timer = Timer(/*maxCount: MAX_COUNT, lblC: lblCounting, progC: progCounting, delaySec: self.delaySecWithOffset*/)

    internal let MAX_COUNT: Int = 10_000
    internal let MAX_DELAY_SEC: Double = 5.0
    internal let MIN_DELAY_SEC: Double = 0.0
    
    internal let lblCounting: UILabel = UILabel(frame: CGRectZero)
    internal let progCounting: UIProgressView = UIProgressView(frame: CGRectZero)
    
    private var delaySecOffset: Double = 0.0
    private var delaySecWithOffset: Double = 0.0 /*{
        //TODO: To be removed
        /*didSet {
            print("Counter delaySecWithOffset didSet:\(delaySecWithOffset)")
        }*/
    }*/
    internal var delaySec: Double = 0.0 {
        //TODO: WillSet To be removed
        /*willSet {
            print("Counter delaySec willSet:\(newValue)")
        }*/
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
        lblCounting.translatesAutoresizingMaskIntoConstraints = false
        progCounting.translatesAutoresizingMaskIntoConstraints = false
        self.lblCounting.textColor = UIColor.whiteColor()
        self.lblCounting.textAlignment = NSTextAlignment.Center
        self.lblCounting.baselineAdjustment = UIBaselineAdjustment.AlignCenters
        self.lblCounting.adjustsFontSizeToFitWidth = true
        self.lblCounting.minimumScaleFactor = 0.05
        self.lblCounting.font = UIFont(name: "Helvetica", size: 400)
        self.lblCounting.text = "0"
        self.progCounting.progressViewStyle = .Bar
        let huePlus180Degrees = hue + 0.5 > 1.0 ? hue + 0.5 - 1.0 : hue + 0.5
        self.progCounting.progressTintColor = UIColor(hue: huePlus180Degrees, saturation: 0.8, brightness: 1.0, alpha: 0.2)
        self.backgroundColor = CounterType.colorWithHue(hue, brightness: brightness)
        self.addSubview(lblCounting)
        self.addSubview(progCounting)
        delaySecOffset = slowDownRandomSec()
        //self.timering = Timer(maxCount: MAX_COUNT, lblC: lblCounting, progC: progCounting)
        //self.running()
        print("Counter init - delaySec:\(delaySecWithOffset)")
        //self.running2()
        self.runningWithCompletion()
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
    
    internal func running() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            for i in 1...self.MAX_COUNT {
                print("delaySecWithOffset:\(self.delaySecWithOffset)")
                NSThread.sleepForTimeInterval(self.delaySecWithOffset)
                dispatch_sync(dispatch_get_main_queue(), {
                    self.lblCounting.text = String(i)
                    self.progCounting.progress = Float(i) / Float(self.MAX_COUNT)
                })
            }
            dispatch_sync(dispatch_get_main_queue(), {
                guard let newEndText = self.delegate!.setCounterTextAfterCountingEnd?() else {
                    return
                }
                self.lblCounting.text = newEndText
            })
        })
    }
    
    internal func running2() {
        /*print("In running2 timer creation - delaySec:\(self.delaySec) delaySecOffset:\(self.delaySecOffset) delaySecWithOffset:\(self.delaySecWithOffset)")

        timering = Timer(maxCount: MAX_COUNT, lblC: lblCounting, progC: progCounting, delaySec: self.delaySecWithOffset)
        
        /*let myBlock = {print("CompletionBlock working!")}
        timering.completionBlock?(myBlock())*/
        //timering.completionBlock?(print("Finished"))

        //timering.timeDelay = self.delaySecWithOffset
        timering!.start()*/
    }
    
    internal func runningWithCompletion() {
        //print("In running2 timer creation - delaySec:\(self.delaySec) delaySecOffset:\(self.delaySecOffset) delaySecWithOffset:\(self.delaySecWithOffset)")
        
        /*let myBlock = {print("CompletionBlock working!")}
        timering.completionBlock?(myBlock())*/
        //timering.completionBlock?(print("Finished"))
        
        //timering.timeDelay = self.delaySecWithOffset
        
        /*let bl = {
            for i in 1...1_000 {
                print(i)
            }
            print("delaySecWithOffset:\(self.delaySecWithOffset)")
        }*/
        
        //let counterRunningBlock =
        timering.start({
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                for i in 1...self.MAX_COUNT {
                    if self.timering.cancelled {break}
                    NSThread.sleepForTimeInterval(self.delaySecWithOffset)
                    dispatch_sync(dispatch_get_main_queue(), {
                        self.lblCounting.text = String(i)
                        self.progCounting.progress = Float(i) / Float(self.MAX_COUNT)
                    })
                }
                dispatch_sync(dispatch_get_main_queue(), {
                    guard let newEndText = self.delegate!.setCounterTextAfterCountingEnd?() else {
                        return
                    }
                    self.lblCounting.text = newEndText
                })
            })
        })
    }
    
    override func removeFromSuperview() {
        timering.cancel()
        //FIXEME: Is this super.remove necessary?
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