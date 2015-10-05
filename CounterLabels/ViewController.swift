//
//  ViewController.swift
//  Animals
//
//  Created by Paulo on 16/08/14.
//  Copyright (c) 2014 xyz. All rights reserved.
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
            }.map{$0.alpha = alpha}
        })
    }
}

class ViewController: UIViewController, UIGestureRecognizerDelegate, CounterDelegate {
    
    @IBOutlet var clickToAddLabel: UITapGestureRecognizer!
    @IBOutlet var dbClickToFillWithLabels: UITapGestureRecognizer!
    @IBOutlet var swipeToRemoveLabel: UISwipeGestureRecognizer!
    @IBOutlet var dbSwipeToRemoveAllLabels: UISwipeGestureRecognizer!
    @IBOutlet var panToAccelerate: UIPanGestureRecognizer!
    
    @IBOutlet weak var bttNumberOfCounters: UIButton!
    @IBOutlet weak var labelInstructions: UILabel!
    //@IBOutlet weak var labelSpeedChangingText: UILabel!
    @IBOutlet weak var labelSpeedChangingValue: UILabel!
    
    let maxCountersPerRowColumn = 6
    var numberOfViewsPerRowColumn = 3
    lazy var allIndicators: (UIView) -> Bool = {($0 is UIButton) || !($0 is Counter)}
    lazy var speedIndicators: (UIView) -> Bool = {($0 is UILabel) && !($0 is Counter) && !($0 is UIButton)}
    var counter = 0
    var overallHue: CGFloat = 0
 
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.userInteractionEnabled = true
        dbClickToFillWithLabels.numberOfTouchesRequired = 2
        swipeToRemoveLabel.direction = UISwipeGestureRecognizerDirection.Left
        dbSwipeToRemoveAllLabels.numberOfTouchesRequired = 2
        dbSwipeToRemoveAllLabels.direction = UISwipeGestureRecognizerDirection.Left
        panToAccelerate.maximumNumberOfTouches = 1
        swipeToRemoveLabel.delegate = self
        //panToAccelerate.delegate = self
        bttNumberOfCounters.titleLabel?.adjustsFontSizeToFitWidth = true
        bttNumberOfCounters.titleLabel?.minimumScaleFactor = 0.3
        bttNumberOfCounters.titleLabel?.baselineAdjustment = .AlignCenters
        bttNumberOfCounters.titleLabel?.text = String(numberOfViewsPerRowColumn)
        
        overallHue = CGFloat(arc4random_uniform(100)) / 100
        self.view.backgroundColor = CounterType.colorWithHue(overallHue, brightness: 0.4) //UIColor(hue: overallHue, saturation: 0.5, brightness: 0.5, alpha: 1.0)
        labelInstructions.textColor = UIColor(hue: overallHue , saturation: 0.5, brightness: 0.9, alpha: 0.5)
        labelSpeedChangingValue.textColor = UIColor(hue: overallHue + 0.5 , saturation: 0.5, brightness: 0.9, alpha: 0.65)
        //labelSpeedChangingText.textColor = UIColor(hue: overallHue + 0.5 , saturation: 0.5, brightness: 0.9, alpha: 0.5)    
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func addLabel() {
        if self.allCounters.count >= 0 && self.allCounters.count <= numberOfViewsPerRowColumn * numberOfViewsPerRowColumn - 1 {
            /*
            var newLabel: CounterLabel
            
            let createCounterLabel = arc4random_uniform(3)
            switch createCounterLabel {
            case 0:
                newLabel = SlowLabel(hue: overallHue)
            case 1:
                newLabel = AverageLabel(hue: overallHue)
            case 2:
                newLabel = FastLabel(hue: overallHue)
            default: ()
                newLabel = SlowLabel(hue: overallHue)
            }
            */
            
            let newLabel = CounterFactory.initWithHue(overallHue)
            ++counter
            newLabel.tag = counter
            newLabel.delegate = self
            newLabel.translatesAutoresizingMaskIntoConstraints = false
            
            //self.view.sendSubviewToBack((labelSpeedChangingText))
            self.view.sendSubviewToBack(labelSpeedChangingValue)
        
            self.view.addSubview(newLabel)
            addGridConstraintsTo(newLabel)
            
            //self.view.bringSubviewToFront(labelSpeedChangingText)
            self.view.bringSubviewToFront(labelSpeedChangingValue)

            // Fade out indicators (views other than CounterLabels) after first counter label added to the view
            if self.allCounters.count == 1 {
                self.fadeWithDuration(alpha: 0.0, indicators: allIndicators, exclude: nil)
            }
        }
    }
    
    func addGridConstraintsTo(newLabel: Counter) {
        // Width and Height with same value constraint
        //self.view.addConstraint(NSLayoutConstraint(item: newLabel, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: newLabel, attribute: NSLayoutAttribute.Height, multiplier: 1, constant: 0))
        
        // Number of labels per column constraint
        self.view.addConstraint(NSLayoutConstraint(item: newLabel, attribute: .Height, relatedBy: NSLayoutRelation.Equal, toItem: self.view , attribute: .Height, multiplier: 1 / CGFloat(numberOfViewsPerRowColumn), constant: 0))
        
        // Number of labels per row constraint
        self.view.addConstraint(NSLayoutConstraint(item: newLabel, attribute: .Width, relatedBy: NSLayoutRelation.Equal, toItem: self.view , attribute: .Width, multiplier: 1 / CGFloat(numberOfViewsPerRowColumn), constant: 0))
        
        // Labels horizontal alignment constraints
        let previouslyCreatedView = self.view.subviews.dropLast().last
        if /*self.counter*/ self.allCounters.count % numberOfViewsPerRowColumn == 1 {
            // Each 1st label in row is left aligned to superview
            self.view.addConstraint(NSLayoutConstraint(item: newLabel , attribute: .Leading, relatedBy: .Equal, toItem: self.view, attribute: .Leading, multiplier: 1, constant: 0))
        } else {
            // Each left label is left aligned to previous one
            self.view.addConstraint(NSLayoutConstraint(item: newLabel , attribute: .Left, relatedBy: NSLayoutRelation.Equal, toItem: previouslyCreatedView!, attribute: .Right, multiplier: 1, constant: 0))
        }
        
        // Labels' vertical alignment constraints
        let rowNumber = (self.allCounters.count - 1) / numberOfViewsPerRowColumn + 1
        if rowNumber == 1 {
            // Align row 1 labels' top to superview's top
            self.view.addConstraint(NSLayoutConstraint(item: newLabel, attribute: .Top , relatedBy: .Equal, toItem: self.view, attribute: .Top, multiplier: 1, constant: 0))
        } else {
            // Other rows, align labels' top to previous row labels' bottoms
            self.view.addConstraint(NSLayoutConstraint(item: newLabel, attribute: .Top , relatedBy: .Equal, toItem: self.view, attribute: .Bottom , multiplier: 1 / CGFloat(numberOfViewsPerRowColumn) * CGFloat(rowNumber - 1), constant: 0))
        }
        
        newLabel.layoutIfNeeded()
        newLabel.font = UIFont(name: newLabel.font.fontName, size: newLabel.frame.height * 1.3)
    }
    
    @IBAction func addAllLabels() {
        let maxOfLabels = numberOfViewsPerRowColumn * numberOfViewsPerRowColumn
        if self.allCounters.count < maxOfLabels {
            for _ in 1...(maxOfLabels - self.allCounters.count) {
                addLabel()
            }
        }
        //self.view.bringSubviewToFront(labelSpeedChangingText)
        self.view.bringSubviewToFront(labelSpeedChangingValue)
    }
    
    @IBAction func removeLabel() {
        if self.allCounters.count > 0 {
            //self.view.subviews.filter{($0 is CounterLabel)}.last?.removeFromSuperview()
            self.allCounters.last?.removeFromSuperview()
            --counter
        }
        if self.allCounters.count == 0 {
            self.fadeWithDuration(alpha: 1.0, indicators: allIndicators, exclude: nil)
        }
    }
    
    @IBAction func removeAllLabels() {
        //let allCounters = self.view.subviews.filter{($0 is CounterLabel)}
        for v in self.allCounters {
            v.removeFromSuperview()
        }
        counter = 0
        self.labelSpeedChangingValue.text = "0.0 s slower"
        self.fadeWithDuration(alpha: 1.0, indicators: allIndicators, exclude: nil)
    }
    
    @IBAction func accelerating(recognizer: UIPanGestureRecognizer) {
        // Accelerating label indicator value changing and on/off of screen
        recognizer.requireGestureRecognizerToFail(swipeToRemoveLabel)
        if recognizer.state == UIGestureRecognizerState.Began {
            self.fadeWithDuration(alpha: 1.0, indicators: speedIndicators, exclude: [labelInstructions])
        } else if recognizer.state == UIGestureRecognizerState.Changed {
            //let allCounters1 = self.allCounters //self.view.subviews.filter{($0 is CounterLabel)}
            self.allCounters.map{ v in
                let counter = v as! Counter //(v as? Counter)!
                let velocity = panToAccelerate.velocityInView(self.view)
                counter.speed += velocity.y > 0 ? 0.1 : -0.1
                labelSpeedChangingValue.text = String(format: "%.1f s slower", counter.speed)
                //print(label.dynamicType, label.tag, ":", label.delaySecWithOffset, label.brightness)
            }
        } else if recognizer.state == UIGestureRecognizerState.Ended {
            self.fadeWithDuration(0.1, alpha: 0.0, indicators: speedIndicators, exclude: [labelInstructions])
        }
    }
    
    @IBAction func changingNumberOfCounters(sender: UIButton) {
        let newNumberOfCounters = numberOfViewsPerRowColumn++ % maxCountersPerRowColumn + 1
        sender.setTitle(String(newNumberOfCounters), forState: .Normal)
        numberOfViewsPerRowColumn = newNumberOfCounters
    }
    
    // Not in use for now
    func runDidEnd(counter: Counter) {
        
    }
    
    func textAfterEnding() -> String? {
        return nil
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

