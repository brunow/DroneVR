//
//  DroneVRUITests.swift
//  DroneVRUITests
//
//  Created by cesar4 on 28/04/16.
//  Copyright © 2016 Parrot. All rights reserved.
//

import XCTest
//import RxSwift

class DroneVRUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        
        let app = XCUIApplication()
        let dronevrIcon = app.scrollViews.otherElements.containingType(.Icon, identifier:"Game Center").childrenMatchingType(.Icon).matchingIdentifier("DroneVR").elementBoundByIndex(1)
        dronevrIcon.tap()
        dronevrIcon.tap()
        dronevrIcon.tap()
        dronevrIcon.tap()
        dronevrIcon.tap()
        dronevrIcon.tap()
        dronevrIcon.tap()
        dronevrIcon.tap()
        dronevrIcon.swipeDown()
        dronevrIcon.tap()
        dronevrIcon.tap()
        app.otherElements.containingType(.Button, identifier:"Fly").element.tap()
        app.buttons["Fly"].tap()
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
}
