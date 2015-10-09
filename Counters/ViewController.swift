//
//
//  Created by Paulo.
//  Copyright (c) 2015 xyz. All rights reserved.
//

import UIKit

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
    
    @IBOutlet weak var bttNumberOfCounters: UIButton!
    @IBOutlet weak var labelInstructions: UILabel!
    @IBOutlet weak var labelSpeedChangingValue: UILabel!
    
    let FONTSIZE_RESCALE: CGFloat = 1.3
    let MAX_COUNTERS_PER_ROW_COLUMN = 6
    
    var numberOfViewsPerRowColumn = 3
    var allIndicators: (UIView) -> Bool = {($0 is UIButton) || !($0 is Counter)}
    var speedIndicators: (UIView) -> Bool = {($0 is UILabel) && !($0 is Counter) && !($0 is UIButton)}
    var overallHue: CGFloat = 0
 
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.userInteractionEnabled = true
        dbTapToFillUpWithCounters.numberOfTouchesRequired = 2
        swipeToRemoveCounter.direction = UISwipeGestureRecognizerDirection.Left
        dbSwipeToRemoveAllCounters.numberOfTouchesRequired = 2
        dbSwipeToRemoveAllCounters.direction = UISwipeGestureRecognizerDirection.Left
        panToAccelerate.maximumNumberOfTouches = 1
        swipeToRemoveCounter.delegate = self
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
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func addCounter() {
        if self.allCounters.count >= 0 && self.allCounters.count <= numberOfViewsPerRowColumn * numberOfViewsPerRowColumn - 1 {
            let newCounter = CounterFactory.initWithHue(overallHue)
            newCounter.delegate = self
            newCounter.translatesAutoresizingMaskIntoConstraints = false
        
            self.view.sendSubviewToBack(labelSpeedChangingValue)
            self.view.addSubview(newCounter)
            addGridConstraintsTo(newCounter)
            self.view.bringSubviewToFront(labelSpeedChangingValue)

            // Fade out indicators (any view other than Counter) after first counter added to the view
            if self.allCounters.count == 1 {
                self.fadeWithDuration(alpha: 0.0, indicators: allIndicators, exclude: nil)
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
        if self.allCounters.count % numberOfViewsPerRowColumn == 1 {
            // Each 1st label in row is left aligned to superview
            self.view.addConstraint(NSLayoutConstraint(item: newCounter , attribute: .Leading, relatedBy: .Equal, toItem: self.view, attribute: .Leading, multiplier: 1, constant: 0))
        } else {
            // Each left label is left aligned to previous one
            self.view.addConstraint(NSLayoutConstraint(item: newCounter , attribute: .Left, relatedBy: NSLayoutRelation.Equal, toItem: previouslyCreatedView!, attribute: .Right, multiplier: 1, constant: 0))
        }
        
        // Labels' vertical alignment constraints
        let rowNumber = (self.allCounters.count - 1) / numberOfViewsPerRowColumn + 1
        if rowNumber == 1 {
            // Align row 1 labels' top to superview's top
            self.view.addConstraint(NSLayoutConstraint(item: newCounter, attribute: .Top , relatedBy: .Equal, toItem: self.view, attribute: .Top, multiplier: 1, constant: 0))
        } else {
            // Other rows, align labels' top to previous row labels' bottoms
            self.view.addConstraint(NSLayoutConstraint(item: newCounter, attribute: .Top , relatedBy: .Equal, toItem: self.view, attribute: .Bottom , multiplier: 1 / CGFloat(numberOfViewsPerRowColumn) * CGFloat(rowNumber - 1), constant: 0))
        }
        
        newCounter.layoutIfNeeded()
        newCounter.font = UIFont(name: newCounter.font.fontName, size: newCounter.frame.height * FONTSIZE_RESCALE)
    }
    
    @IBAction func addAllCounters() {
        let maxOfCounters = numberOfViewsPerRowColumn * numberOfViewsPerRowColumn
        if self.allCounters.count < maxOfCounters {
            for _ in 1...(maxOfCounters - self.allCounters.count) {
                addCounter()
            }
        }
        self.view.bringSubviewToFront(labelSpeedChangingValue)
    }
    
    @IBAction func removeCounter() {
        if self.allCounters.count > 0 {
            self.allCounters.last?.removeFromSuperview()
        }
        if self.allCounters.count == 0 {
            self.fadeWithDuration(alpha: 1.0, indicators: allIndicators, exclude: nil)
        }
    }
    
    @IBAction func removeAllCounters() {
        self.allCounters.forEach{v in v.removeFromSuperview()}
        self.labelSpeedChangingValue.text = "0.0s slower"
        self.fadeWithDuration(alpha: 1.0, indicators: allIndicators, exclude: nil)
    }
    
    @IBAction func accelerating(recognizer: UIPanGestureRecognizer) {
        // Accelerating label indicator value changing and on/off of screen
        recognizer.requireGestureRecognizerToFail(swipeToRemoveCounter)
        if recognizer.state == UIGestureRecognizerState.Began {
            self.fadeWithDuration(alpha: 1.0, indicators: speedIndicators, exclude: [labelInstructions])
        } else if recognizer.state == UIGestureRecognizerState.Changed {
            self.allCounters.forEach{ view in
                let counter = view as! Counter
                let velocity = panToAccelerate.velocityInView(self.view)
                counter.speed += velocity.y > 0 ? 0.1 : -0.1
                labelSpeedChangingValue.text = String(format: "%.1fs slower", counter.speed)
            }
        } else if recognizer.state == UIGestureRecognizerState.Ended {
            self.fadeWithDuration(0.1, alpha: 0.0, indicators: speedIndicators, exclude: [labelInstructions])
        }
    }
    
    @IBAction func changingNumberOfCounters(sender: UIButton) {
        let newNumberOfCounters = numberOfViewsPerRowColumn++ % MAX_COUNTERS_PER_ROW_COLUMN + 1
        sender.setTitle(String(newNumberOfCounters), forState: .Normal)
        numberOfViewsPerRowColumn = newNumberOfCounters
    }
    
    // CounterDelegate optional method
    func setCounterTextAfterCountingEnd() -> String {
        return "yeah!"
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.All
    }
    
    // When rotating from portrait orientation counters have to be redrawn. Numbers inferior to 10 font's size are bigger than label size
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        if fromInterfaceOrientation == .Portrait || fromInterfaceOrientation == .PortraitUpsideDown {
            view.layoutIfNeeded()
            self.allCounters.forEach{ view in
                let label = (view as! UILabel)
                label.font = UIFont(name: label.font.fontName, size: label.frame.height * FONTSIZE_RESCALE)
            }
        }
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

