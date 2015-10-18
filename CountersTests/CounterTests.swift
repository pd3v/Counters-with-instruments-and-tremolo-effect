//
//  CountersTests.swift
//  CountersTests
//
//  Created by Paulo on 14/10/15.
//  Copyright © 2015 xyz. All rights reserved.
//

import XCTest
@testable import Counters

class CounterTests: XCTestCase {
    
    func testCounterIsAlwaysCreated() {
        XCTAssertNotNil(CounterFactory.initWithHue(0.5))
    }
    
    func testCounterSpeedIsLessOrEqualToFive() {
        let counter = Counter(hue: 0.5)
        counter.speed = 6
        XCTAssertLessThanOrEqual(counter.speed, 5)
    }
    
    func testCounterSpeedIsGreaterOrEqualToZero() {
        let counter = Counter(hue: 0.5)
        counter.speed = -1
        XCTAssertGreaterThanOrEqual(counter.speed, 0)
    }
}