//
//	DroneVR.
//	Created by:				Bruno Wernimont
//
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//	THE SOFTWARE.

import Foundation
import GameController
import RxSwift
import RxCocoa

class GamePadViewModel: NSObject {
    
    private dynamic var gameController: GCController?
    private let disposeBag = DisposeBag()
    
    let controllerStateDidChange: PublishSubject<Bool> = PublishSubject()
    
    let padLeftXAxis: Variable<Float> = Variable(0)
    let padLeftYAxis: Variable<Float> = Variable(0)
    let padRightXAxis: Variable<Float> = Variable(0)
    let padRightYAxis: Variable<Float> = Variable(0)
    
    let aPressed: PublishSubject<Void> = PublishSubject()
    let bPressed: PublishSubject<Void> = PublishSubject()
    let xPressed: PublishSubject<Void> = PublishSubject()
    let yPressed: PublishSubject<Void> = PublishSubject()
    
    let leftTwoPressed: PublishSubject<Void> = PublishSubject()
    let rightTwoPressed: PublishSubject<Void> = PublishSubject()
    let leftOnePressed: PublishSubject<Void> = PublishSubject()
    let rightOnePressed: PublishSubject<Void> = PublishSubject()
    
    static let sharedInstance = GamePadViewModel()
    
    override init() {
        super.init()
        
        self.rx_observe(GCController.self, "gameController").subscribeNext { [unowned self] gameController in
            self.bindWithViewModel()
            self.controllerStateDidChange.onNext(self.connected())
        }.addDisposableTo(disposeBag)
        
        let gamePadDidConnectSignal = NSNotificationCenter.defaultCenter()
            .rx_notification(GCControllerDidConnectNotification)
            .map { _ in return true }
        
        let gamePadDidDisconnectSignal = NSNotificationCenter.defaultCenter()
            .rx_notification(GCControllerDidDisconnectNotification)
            .map { _ in return false }
        
        gamePadDidConnectSignal.subscribeNext { [unowned self] _ in
            self.gameController = self.findGameController()
        }.addDisposableTo(disposeBag)
        
        gamePadDidDisconnectSignal.subscribeNext { [unowned self] _ in
            self.gameController = self.findGameController()
        }.addDisposableTo(disposeBag)
        
        self.gameController = self.findGameController()
        self.startDiscovering()
    }
    
    deinit {
        self.stopDiscovering()
    }
    
    func connected() -> Bool {
        return self.gameController != nil
    }
    
    func startDiscovering() {
        GCController.startWirelessControllerDiscoveryWithCompletionHandler { [unowned self] in
            self.gameController = self.findGameController()
        }
    }
    
    func stopDiscovering() {
        GCController.stopWirelessControllerDiscovery()
    }
    
    // MARK: Private
    
    private func bindWithViewModel() {
        self.gameController?.extendedGamepad!.leftThumbstick.valueChangedHandler = { [unowned self] _, xValue, yValue in
            self.padLeftXAxis.value = xValue
            self.padLeftYAxis.value = yValue
        }
        
        self.gameController?.extendedGamepad!.rightThumbstick.valueChangedHandler = { [unowned self] _, xValue, yValue in
            self.padRightXAxis.value = xValue
            self.padRightYAxis.value = yValue
        }
        
        self.gameController?.extendedGamepad!.buttonA.pressedChangedHandler = { [unowned self] _, _, pressed in
            if pressed {
                self.aPressed.onNext()
            }
        }
        
        self.gameController?.extendedGamepad!.buttonB.pressedChangedHandler = { [unowned self] _, _, pressed in
            if pressed {
                self.bPressed.onNext()
            }
        }
        
        self.gameController?.extendedGamepad!.buttonX.pressedChangedHandler = { [unowned self] _, _, pressed in
            if pressed {
                self.xPressed.onNext()
            }
        }
        
        self.gameController?.extendedGamepad!.buttonY.pressedChangedHandler = { [unowned self] _, _, pressed in
            if pressed {
                self.yPressed.onNext()
            }
        }
        
        self.gameController?.extendedGamepad!.leftTrigger.pressedChangedHandler = { [unowned self] _, _, pressed in
            if pressed {
                self.leftTwoPressed.onNext()
            }
        }
        
        self.gameController?.extendedGamepad!.rightTrigger.pressedChangedHandler = { [unowned self] _, _, pressed in
            if pressed {
                self.rightTwoPressed.onNext()
            }
        }
        
        self.gameController?.extendedGamepad!.leftShoulder.pressedChangedHandler = { [unowned self] _, _, pressed in
            if pressed {
                self.leftOnePressed.onNext()
            }
        }
        
        self.gameController?.extendedGamepad!.rightShoulder.pressedChangedHandler = { [unowned self] _, _, pressed in
            if pressed {
                self.rightOnePressed.onNext()
            }
        }
    }
    
    private func findGameController() -> GCController? {
        if GCController.controllers().count > 0 {
            let controller = GCController.controllers().first
            if ((controller?.extendedGamepad) != nil) {
                return controller
            }
        }
        
        return nil
    }
}
