//
//
//  Created by Paulo.
//  Copyright (c) 2015 xyz. All rights reserved.
//

import UIKit
import AVFoundation
import TremoloEffectKit

extension UIViewController {
    var allCounters: [UIView] {
        return self.view.subviews.filter{($0 is Counter)}
    }

    func fadeWithDuration(duration: NSTimeInterval = 0.2, alpha: CGFloat, indicators: (UIView) -> Bool, exclude: Set<UIView>?) {
        UIView.animateWithDuration(duration, animations: {
            self.view.subviews.filter(indicators).filter{
                for view in exclude ?? [] {
                    return $0 != view
                }
                return true
            }.forEach{$0.alpha = alpha}
        })
    }
}

class ViewController: UIViewController, UIGestureRecognizerDelegate, CounterDelegate {
    @IBOutlet var tapToAddCounter: UITapGestureRecognizer!
    @IBOutlet var dbTapToFillUpWithCounters: UITapGestureRecognizer!
    @IBOutlet var swipeToRemoveCounter: UISwipeGestureRecognizer!
    @IBOutlet var dbSwipeToRemoveAllCounters: UISwipeGestureRecognizer!
    @IBOutlet var panToAccelerate: UIPanGestureRecognizer!
    @IBOutlet var longPressToShowSpeedIndicator: UILongPressGestureRecognizer!
    
    @IBOutlet weak var bttNumberOfCounters: UIButton!
    @IBOutlet weak var labelInstructions: UILabel!
    @IBOutlet weak var labelSpeedChangingValue: UILabel!
    
    let FONTSIZE_RESCALE: CGFloat = 1.3
    let MAX_COUNTERS_PER_ROW_COLUMN = 3
    
    let engine = AVAudioEngine()
    let reverb = AVAudioUnitReverb()
    var tremolo = AVAudioUnit() // Audio tremolo effect
    let mixer = AVAudioMixerNode()
    
    var depthParameter: AUParameter!
    var rateFrequencyParameter: AUParameter!
    var parameterObserverToken: AUParameterObserverToken!
    
    var numberOfViewsPerRowColumn = 3
    var allIndicators: (UIView) -> Bool = {($0 is UIButton) || !($0 is Counter)}
    var speedIndicators: (UIView) -> Bool = {($0 is UILabel) && !($0 is Counter) && !($0 is UIButton)}
    var overallHue: CGFloat = 0
    
    var reverbWetDryMix: Float = 100.0 {
        willSet {
            if newValue >= 0 && newValue <= 100  {
                reverb.wetDryMix += newValue - reverbWetDryMix
            }
        }
        didSet {
            if reverbWetDryMix <= 0 {
                reverbWetDryMix = 0
                reverb.wetDryMix = 0
            }
            else if reverbWetDryMix >= 100 {
                reverbWetDryMix = 100
                reverb.wetDryMix = 100
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.userInteractionEnabled = true
        dbTapToFillUpWithCounters.numberOfTouchesRequired = 2
        swipeToRemoveCounter.direction = UISwipeGestureRecognizerDirection.Left
        dbSwipeToRemoveAllCounters.numberOfTouchesRequired = 2
        dbSwipeToRemoveAllCounters.direction = UISwipeGestureRecognizerDirection.Left
        panToAccelerate.maximumNumberOfTouches = 1
        swipeToRemoveCounter.delegate = self
        longPressToShowSpeedIndicator.delegate = self
        bttNumberOfCounters.titleLabel?.baselineAdjustment = .AlignCenters
        bttNumberOfCounters.titleLabel?.text = String(numberOfViewsPerRowColumn)
        labelSpeedChangingValue.adjustsFontSizeToFitWidth = true
        labelSpeedChangingValue.minimumScaleFactor = 0.4
        labelSpeedChangingValue.layer.masksToBounds = true
        labelSpeedChangingValue.layer.cornerRadius = 8.0
        overallHue = CGFloat(arc4random_uniform(100)) / 100
        self.view.backgroundColor = CounterType.colorWithHue(overallHue, brightness: 0.4)
        labelInstructions.textColor = UIColor(hue: overallHue , saturation: 0.5, brightness: 0.9, alpha: 0.45)
        labelSpeedChangingValue.textColor = UIColor(hue: 1.0 , saturation: 0.0, brightness: 1.0, alpha: 0.45) // White color
        labelSpeedChangingValue.backgroundColor = UIColor(hue: 1.0, saturation: 1.0, brightness: 0.0, alpha: 0.45) // Black color
        
        // - Registring in Audio Component system and instantiating custom-made Tremolo effect -
        var componentDescription = AudioComponentDescription()
        componentDescription.componentType = kAudioUnitType_Effect
        componentDescription.componentSubType = 0
        componentDescription.componentManufacturer = kAudioUnitManufacturer_Apple
        componentDescription.componentFlags = 0
        componentDescription.componentFlagsMask = 0
        
        AUAudioUnit.registerSubclass(AUAudioTremolo.self, asComponentDescription: componentDescription, name: "Awesome Tremolo", version: UInt32.max)
        AVAudioUnit.instantiateWithComponentDescription(componentDescription, options: []) { avAudioUnit, error in
            guard let avAudioUnit = avAudioUnit else { return }
            self.tremolo = avAudioUnit
            self.engine.attachNode(self.tremolo)
        }
        // - - -
        
        guard let parameterTree = tremolo.AUAudioUnit.parameterTree else { return }
        depthParameter = parameterTree.valueForKey("depth") as? AUParameter
        rateFrequencyParameter = parameterTree.valueForKey("rateFrequency") as? AUParameter
        
        engine.attachNode(reverb)
        reverb.loadFactoryPreset(.LargeHall2)
        reverb.wetDryMix = 100
        engine.attachNode(mixer)
        mixer.outputVolume = 0.99
        engine.mainMixerNode.outputVolume = 0.99 // Volume < 1.0 to add some room to avoid distortion
        engine.connect(mixer, to: tremolo, format: nil)
        engine.connect(tremolo, to: reverb, format: nil)
        engine.connect(reverb, to: engine.mainMixerNode, format: SimpleSynth().outputFormatForBus(0))
        engine.prepare()
    
        setTremoloParameters()
        
        do {
            try engine.start()
        } catch let error as NSError {
            print("error:\(error.localizedDescription)")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func addCounter() {
        if allCounters.count >= 0 && allCounters.count <= numberOfViewsPerRowColumn * numberOfViewsPerRowColumn - 1 {
            let newCounter = CounterFactory.initWithHue(overallHue)
            newCounter.delegate = self
            newCounter.translatesAutoresizingMaskIntoConstraints = false
            
            self.view.sendSubviewToBack(labelSpeedChangingValue)
            self.view.addSubview(newCounter)
            addGridConstraintsTo(newCounter)
            self.view.bringSubviewToFront(labelSpeedChangingValue)
            
            relevelSynthsVolumes()
            engine.attachNode(newCounter.synth)
            engine.connect(newCounter.synth, to: mixer, format: mixer.outputFormatForBus(0))
            // buffer == nil -> use default built-in soundwave
            newCounter.synth.scheduleBuffer(nil, atTime: nil, options: .Interrupts, completionHandler: nil) // Attack
            newCounter.synth.scheduleBuffer(nil, atTime: nil, options: .Loops, completionHandler: nil) // Sustain

            // Fade out indicators (any view other than Counter) after first counter added to the view
            if allCounters.count == 1 {
                fadeWithDuration(alpha: 0.0, indicators: allIndicators, exclude: nil)
            }
        }
    }
    
    func addGridConstraintsTo(newCounter: Counter) {
        // Width and Height with same value constraint
        //self.view.addConstraint(NSLayoutConstraint(item: newCounter, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: newCounter, attribute: NSLayoutAttribute.Height, multiplier: 1, constant: 0))
        
        // Number of labels per column constraint
        self.view.addConstraint(NSLayoutConstraint(item: newCounter, attribute: .Height, relatedBy: NSLayoutRelation.Equal, toItem: self.view , attribute: .Height, multiplier: 1 / CGFloat(numberOfViewsPerRowColumn), constant: 0))
        
        // Number of labels per row constraint
        self.view.addConstraint(NSLayoutConstraint(item: newCounter, attribute: .Width, relatedBy: NSLayoutRelation.Equal, toItem: self.view , attribute: .Width, multiplier: 1 / CGFloat(numberOfViewsPerRowColumn), constant: 0))
        
        // Labels horizontal alignment constraints
        let previouslyCreatedView = self.view.subviews.dropLast().last
        if allCounters.count % numberOfViewsPerRowColumn == 1 {
            // Each 1st label in row is left aligned to superview
            self.view.addConstraint(NSLayoutConstraint(item: newCounter , attribute: .Leading, relatedBy: .Equal, toItem: self.view, attribute: .Leading, multiplier: 1, constant: 0))
        } else {
            // Each left label is left aligned to previous one
            self.view.addConstraint(NSLayoutConstraint(item: newCounter , attribute: .Left, relatedBy: NSLayoutRelation.Equal, toItem: previouslyCreatedView!, attribute: .Right, multiplier: 1, constant: 0))
        }
        
        // Labels' vertical alignment constraints
        let rowNumber = (allCounters.count - 1) / numberOfViewsPerRowColumn + 1
        if rowNumber == 1 {
            // Align row 1 labels' top to superview's top
            self.view.addConstraint(NSLayoutConstraint(item: newCounter, attribute: .Top , relatedBy: .Equal, toItem: self.view, attribute: .Top, multiplier: 1, constant: 0))
        } else {
            // Other rows, align labels' top to previous row labels' bottoms
            self.view.addConstraint(NSLayoutConstraint(item: newCounter, attribute: .Top , relatedBy: .Equal, toItem: self.view, attribute: .Bottom , multiplier: 1 / CGFloat(numberOfViewsPerRowColumn) * CGFloat(rowNumber - 1), constant: 0))
        }
        
        newCounter.layoutIfNeeded()
        newCounter.lblCounting.font = UIFont(name: newCounter.lblCounting.font.fontName, size: newCounter.frame.height * FONTSIZE_RESCALE)
    }
    
    @IBAction func addAllCounters() {
        let maxOfCounters = numberOfViewsPerRowColumn * numberOfViewsPerRowColumn
        if allCounters.count < maxOfCounters {
            for _ in 1...(maxOfCounters - allCounters.count) {
                addCounter()
            }
        }
        self.view.bringSubviewToFront(labelSpeedChangingValue)
    }
    
    @IBAction func removeCounter() {
        if allCounters.count > 0 {
            engine.detachNode((allCounters.last as! Counter).synth) // No new counter/synth will be reused
            allCounters.last?.removeFromSuperview()
        }
        if allCounters.count == 0 {
            labelSpeedChangingValue.text = "0.0s slower reverb 100%"
            fadeWithDuration(alpha: 1.0, indicators: allIndicators, exclude: nil)
            setTremoloParameters()
        }
        relevelSynthsVolumes()
    }
    
    @IBAction func removeAllCounters() {
        allCounters.forEach{view in
            engine.detachNode((view as! Counter).synth) // No new counters/synths will be reused
            view.removeFromSuperview()
        }
        labelSpeedChangingValue.text = "0.0s slower reverb 100%"
        fadeWithDuration(alpha: 1.0, indicators: allIndicators, exclude: nil)
        setTremoloParameters()
    }
    
    @IBAction func accelerating(recognizer: UIPanGestureRecognizer) {
        // Accelerating label indicator value changing and on/off of screen
        recognizer.requireGestureRecognizerToFail(swipeToRemoveCounter)
        if recognizer.state == .Began {
            fadeWithDuration(alpha: 1.0, indicators: speedIndicators, exclude: [labelInstructions])
        } else if recognizer.state == .Changed {
            let velocity = panToAccelerate.velocityInView(self.view)
            allCounters.forEach{ view in
                let counter = view as! Counter
                counter.speed += velocity.y > 0 ? 0.1 : -0.1
                labelSpeedChangingValue.text = String(format: "%.1fs slower reverb %3.f%%", counter.speed, reverbWetDryMix)
            }
            reverbWetDryMix += velocity.y > 0 ? -2 : 2 // Reverb wetDryMix varies inversely with counting speed
        } else if recognizer.state == .Ended {
            fadeWithDuration(0.1, alpha: 0.0, indicators: speedIndicators, exclude: [labelInstructions])
        }
    }
    
    @IBAction func showSpeedIndicator(recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .Began {
            fadeWithDuration(alpha: 1.0, indicators: speedIndicators, exclude: [labelInstructions])
        } else if recognizer.state == .Ended {
            fadeWithDuration(alpha: 0.0, indicators: speedIndicators, exclude: [labelInstructions])
        }
    }
    
    @IBAction func changingNumberOfCounters(sender: UIButton) {
        let newNumberOfCounters = numberOfViewsPerRowColumn % MAX_COUNTERS_PER_ROW_COLUMN + 1
        sender.setTitle(String(newNumberOfCounters), forState: .Normal)
        numberOfViewsPerRowColumn += 1
        numberOfViewsPerRowColumn = newNumberOfCounters
    }
    
    // - CounterDelegate optional methods -
    func setCounterTextAfterCountingEnd() -> String {
        return "Yeah!"
    }
    
    func didFinishCounting(counter: Counter) {
        counter.synth.scheduleBuffer(nil, atTime: nil, options: .InterruptsAtLoop, completionHandler: nil) // Release
    }
    // - - -
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.All
    }
    
    // When rotating from portrait orientation counters have to be laid out. UILabels don't resize font height.
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        if fromInterfaceOrientation == .Portrait || fromInterfaceOrientation == .PortraitUpsideDown {
            view.layoutIfNeeded()
            allCounters.forEach{ view in
                view.subviews.forEach{ subview in
                    guard let label = (subview as? UILabel) else {
                        return
                    }
                    label.font = UIFont(name: label.font.fontName, size: label.frame.height * FONTSIZE_RESCALE)
                }
            }
        }
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?)
    {
        if motion == .MotionShake {
            setTremoloParameters()
        }
    }
    
    func relevelSynthsVolumes() {
        // Relevel synths' volume <= 1.0 to prevent distortion when adding new synths
        allCounters.forEach{ view in
            (view as! Counter).synth.volume = 1.0 / Float(allCounters.count)
        }
    }

    func setTremoloParameters() {
        // Randoms frequencies between 0Hz and 20Hz that are multiples of snapFrequency. 
        // 0Hz is no tremolo
        let snapFrequency:Float = 4
        var rateFrequency = Float(arc4random_uniform(UInt32(20 + snapFrequency)))
        rateFrequency -= rateFrequency % snapFrequency
        
        depthParameter.value = 100.0 // For maximum effect
        rateFrequencyParameter.value = Float(rateFrequency)
    }
}

