//
//  CountersTests.swift
//  CountersTests
//
//  Created by Paulo on 14/10/15.
//  Copyright © 2015 xyz. All rights reserved.
//

import XCTest
@testable import Counters

class CounterTests: XCTestCase, CounterDelegate {
    
    var didFinishExpectation: XCTestExpectation?
    
    // CounterDelegate optional method
    func didFinishCounting(c: Counter) {
        self.didFinishExpectation?.fulfill()
    }

    func testCounterIsAlwaysCreated() {
        XCTAssertNotNil(CounterFactory.initWithHue(0.5))
    }
    
    // Performance will depend on Counter MAX_COUNT value which is resettable.
    func testCounterCountingLoopPerformance() {
        self.didFinishExpectation = self.expectationWithDescription("Counter counting finished")
        let counter = Counter(hue: 0.5)
        counter.delegate = self
        self.waitForExpectationsWithTimeout(30, handler: nil)
        counter.running()
    }
    
    func testCounterCountingAlwaysFinishes() {
        self.didFinishExpectation = self.expectationWithDescription("Counter counting finished")
        let counter = Counter(hue: 0.5)
        counter.delegate = self
        self.waitForExpectationsWithTimeout(15, handler: nil)
        XCTAssertEqual(counter.text!, String(counter.MAX_COUNT))
    }
    
    func testSpeedIsLessOrEqualToFive() {
        let counter = Counter(hue: 0.5)
        counter.speed = 6
        XCTAssertLessThanOrEqual(counter.speed, 5)
    }
    
    func testSpeedIsGreaterOrEqualToZero() {
        let counter = Counter(hue: 0.5)
        counter.speed = -1
        XCTAssertGreaterThanOrEqual(counter.speed, 0)
    }
}
