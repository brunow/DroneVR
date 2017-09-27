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

import UIKit
import CoreMotion
import RxSwift

class VirtualRealityViewModel: NSObject {
    
    private let motionManager = CMMotionManager()
    private let queue = NSOperationQueue()
    private var refAttitude: CMAttitude?
    
    dynamic var roll: Double = 0
    dynamic var yaw: Double = 0
    let didUpdateMotion = PublishSubject<(Double, Double)>()
    
    override init() {
        self.motionManager.deviceMotionUpdateInterval = 1 / 30
//        self.motionManager.deviceMotionUpdateInterval = 1
    }
    
    func reset() {
        self.refAttitude = nil
    }
    
    func start() {
        self.motionManager.startDeviceMotionUpdatesToQueue(self.queue) { [weak self] deviceMotion, error in
            guard let _self = self else { return }
            if let deviceMotion = deviceMotion {
                if _self.refAttitude == nil {
                    _self.refAttitude = deviceMotion.attitude
                }
                
                deviceMotion.attitude.multiplyByInverseOfAttitude(_self.refAttitude!)
                
//                let d = UIDevice.currentDevice().orientation.isLandscape
                
                let newRoll = -(deviceMotion.attitude.roll.radiansToDegrees + 90)
                let newYaw = -deviceMotion.attitude.yaw.radiansToDegrees
                
                let valueChanged = _self.roll != newRoll && _self.yaw != newYaw
                
                _self.roll = newRoll
                _self.yaw = newYaw

//                print("roll \(self.roll) yaw \(self.yaw)")
                
                if valueChanged {
                    print("roll \(Int(_self.roll)) yaw \(Int(_self.yaw))")
                    _self.didUpdateMotion.onNext((_self.roll, _self.yaw))
                }
            }
        }
    }
    
    func stop() {
        self.motionManager.stopDeviceMotionUpdates()
    }
    
}
