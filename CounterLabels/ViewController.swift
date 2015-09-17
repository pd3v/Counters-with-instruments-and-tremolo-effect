//
//  ViewController.swift
//  Animals
//
//  Created by Paulo on 16/08/14.
//  Copyright (c) 2014 xyz. All rights reserved.
//

import UIKit

class ViewController: UIViewController, StateDelegate {
    
    @IBOutlet var doubleClick: UITapGestureRecognizer!
    @IBOutlet var swipeMove: UISwipeGestureRecognizer!
    
    let numberOfViewsPerRow = 8
    var counter = 0
    var rankingPosition = 0
    //var firstLabelInRow: UIView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.userInteractionEnabled = true
        doubleClick.numberOfTapsRequired = 1
        swipeMove.numberOfTouchesRequired = 1
        swipeMove.direction = UISwipeGestureRecognizerDirection.Left
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // TODO: If labels are simultaneously "almost" created, the newers ones don't start looping imediatly. How to put all on wait and start all at once?
    @IBAction func addLabel() {
        //print("firstLabelInRow:", firstLabelInRow)
        if self.counter >= 0 && self.counter <= numberOfViewsPerRow * numberOfViewsPerRow - 1 {
            var newLabel: CounterLabel = CounterLabel()
            
            //FIXME: Create Animals with Factory DP to avoid knowing previously all the animals that are subclassed
            let iFeelLike = arc4random_uniform(3)
            //print("iFeelLike:\(iFeelLike)")
            switch iFeelLike {
            case 0:
                newLabel = SlowLabel()
            case 1:
                newLabel = AverageLabel()
            case 2:
                newLabel = FastLabel()
            default:
                newLabel = SlowLabel()
            }
            ++self.counter
            newLabel.tag = self.counter
            newLabel.delegate = self
            newLabel.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(newLabel)
            
            // Width and Height with same value constraint
            //self.view.addConstraint(NSLayoutConstraint(item: newLabel, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: newLabel, attribute: NSLayoutAttribute.Height, multiplier: 1, constant: 0))
            
            // Number of labels per column constraint
            let a = NSLayoutConstraint(item: newLabel, attribute: .Height, relatedBy: NSLayoutRelation.Equal, toItem: self.view , attribute: .Height, multiplier: 1 / CGFloat(numberOfViewsPerRow), constant: 0)
            a.identifier = "h" + String(self.counter)
            self.view.addConstraint(a)
            
            // Number of labels per row constraint
            self.view.addConstraint(NSLayoutConstraint(item: newLabel, attribute: .Width, relatedBy: NSLayoutRelation.Equal, toItem: self.view , attribute: .Width, multiplier: 1 / CGFloat(numberOfViewsPerRow), constant: 0))
            
            // Labels horizontal alignment constraints
            let previouslyCreatedView = self.view.subviews.dropLast().last
            if self.counter % numberOfViewsPerRow == 1 {
                newLabel.notes += "*1st label in row (self.leadind to superview.leading)"
                // Each 1st label in row is left aligned to superview
                self.view.addConstraint(NSLayoutConstraint(item: newLabel , attribute: .Leading, relatedBy: .Equal, toItem: self.view, attribute: .Leading, multiplier: 1, constant: 0))
                // Excluding _UILayoutGuide views
                /*
                if previouslyCreatedView is UILabel {
                    newLabel.notes += "*1st label in row to be vertical ref (firstLabelInRow)"
                    firstLabelInRow = previouslyCreatedView!
                }
                */
            } else {
                // Each left label is left aligned to previous one
                newLabel.notes += "*Left aligned to previous one (self.left to prev.right)"
                self.view.addConstraint(NSLayoutConstraint(item: newLabel , attribute: .Left, relatedBy: NSLayoutRelation.Equal, toItem: previouslyCreatedView!, attribute: .Right, multiplier: 1, constant: 0))
            }
            
            // Labels' vertical alignment constraints
            let rowNumber = (self.counter - 1) / numberOfViewsPerRow + 1
            if rowNumber == 1 {
                newLabel.notes += "*1st line"
                // Align row 1 labels' top to superview's top
                self.view.addConstraint(NSLayoutConstraint(item: newLabel, attribute: .Top , relatedBy: .Equal, toItem: self.view, attribute: .Top, multiplier: 1, constant: 0))
            } else {
                newLabel.notes += "*Other than 1st line"
                // Other rows, align labels' top to previous row labels' bottoms
                self.view.addConstraint(NSLayoutConstraint(item: newLabel, attribute: .Top , relatedBy: .Equal, toItem: self.view, attribute: .Bottom , multiplier: 1 / CGFloat(numberOfViewsPerRow) * CGFloat(rowNumber - 1), constant: 0))
            }
        }
    }
    
    // FIXME: Rename to removeLabel
    @IBAction func deleteLabel() {
        // FIXME: Crashes on removing some (which?) labels
        // Removing one-by-one
        if self.counter > 0 {
        let labelToRemove = (self.view.subviews.last as? CounterLabel)
        let labelWillBeLast = self.view.subviews.dropLast().last
        /*
        let labelToBeConst = labelToBe?.constraints
        labelToBe?.removeConstraints(labelToBeConst!)
        */
        
        //print(labelToRemove?.notes, labelToRemove!)
        labelToRemove?.removeFromSuperview()
        
        //print(self.view.hasAmbiguousLayout())
        /*for v in self.view.subviews {
            print(v.tag, "-", v.hasAmbiguousLayout())
        }*/

        labelWillBeLast?.setNeedsUpdateConstraints()
        //labelWillBeLast?.setNeedsLayout()
        
        --self.counter
        //print(self.counter)
        --self.rankingPosition
        
        // Removing all labels at once
        /*for label in self.view.subviews as [UIView] {
            label.removeFromSuperview()
        }
        self.counter = 0
        self.rankingPosition = 0
        */
        }
    }
    
    func runDidEnd(label: CounterLabel) {
        //label.text = String(++self.rankingPosition) + "º"
    }
}

