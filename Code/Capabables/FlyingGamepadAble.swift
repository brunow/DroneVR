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
import RxSwift

protocol FlyingGamepadAble: class {
    func makeGamepadable(gamePad: GamePadViewModel, config: DroneConfigViewModel, vr: VirtualRealityViewModel?)
}

extension FlyingGamepadAble where Self:Disposable, Self:Dronable {
    func makeGamepadable(gamePad: GamePadViewModel, config: DroneConfigViewModel, vr: VirtualRealityViewModel?) {
        let drone = self.drone
        
        if drone.hasCamera() {
            gamePad.rightTwoPressed
                .flatMap { return drone.takePhoto() }
                .subscribeNext { _ in
                }.addDisposableTo(disposeBag)
            
            gamePad.leftTwoPressed
                .flatMap { drone.startRecordingMovie(!drone.recording.value) }
                .subscribeNext { _ in
                    
                }.addDisposableTo(disposeBag)
        }
        
//        if let vr = vr {
//            gamePad.rightOnePressed
//                .subscribeNext {
//                    vr.reset()
//                }.addDisposableTo(disposeBag)
//        }
        
        gamePad.xPressed
            .flatMap { return config.toggleDistanceType() }
            .subscribeNext { _ in
                
            }.addDisposableTo(disposeBag)
        
        gamePad.bPressed
            .flatMap { return config.toggleSpeedType() }
            .subscribeNext { _ in
                
            }.addDisposableTo(disposeBag)
        
        gamePad.leftOnePressed.subscribeNext {
            // show hud
        }.addDisposableTo(disposeBag)
        
        gamePad.aPressed
            .flatMap { return drone.toggleTakeOff() }
            .subscribeNext { _ in
                
            }.addDisposableTo(disposeBag)
        
        gamePad.yPressed
            .flatMap { return drone.emergency() }
            .subscribeNext { _ in
                
            }.addDisposableTo(disposeBag)
        
        gamePad.padLeftXAxis.asObservable()
            .flatMap { return drone.yaw($0) }
            .subscribeNext { _ in
                
            }.addDisposableTo(disposeBag)
        
        gamePad.padLeftYAxis.asObservable()
            .flatMap { return drone.gaz($0) }
            .subscribeNext { _ in
                
            }.addDisposableTo(disposeBag)
        
        gamePad.padRightYAxis.asObservable()
            .flatMap { return drone.pitch($0) }
            .subscribeNext { _ in
                
            }.addDisposableTo(disposeBag)
        
        gamePad.padRightXAxis.asObservable()
            .flatMap { return drone.roll($0) }
            .subscribeNext { _ in
                
            }.addDisposableTo(disposeBag)
    }
    
}