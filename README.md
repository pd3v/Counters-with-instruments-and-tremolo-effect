# Counters
iOS 8.4 Universal app with the purpose of testing some programming ideas. Fills the screen up with a resettable number of counters. Every counter has its own initial speed (and a matching color brightness) but changeable while counting is running. Developed with Autolayout, multi-threading (with GCD and NSOperation) and gesture recognition.

Updated so that every Counter has now a UIProgressView to shown counting progression. This progression is viable from left-to-right (default) but also from right-to-left with a tap on the Counter view.

## App's initial screen
![intial_screen](https://github.com/pd3v/Counters/blob/master/Screenshots/Initial%20screen.PNG)

## 3x3 counters screen with speed changing indicator
![3x3_counters_screen_with_speed_changing_ indicator](https://github.com/pd3v/Counters/blob/master/Screenshots/counters%20running.PNG)

##Autolayout doing its work on a 6x6 counters screen
![3x3_counters_screen_in_portrait_orientation](https://github.com/pd3v/Counters/blob/master/Screenshots/counters%20running%202.png)

String "yeah!" is shown when counter finishes counting. This string is settable using a delegate method in the viewcontroller.
