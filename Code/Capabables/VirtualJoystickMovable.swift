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

protocol VirtualJoystickMovable: class {
    func makeVirtualJoysticlMovable(leftControlView leftControlView: JoystickView,
                                                    rightControlView: JoystickView)
}

extension VirtualJoystickMovable where Self:Disposable, Self:Dronable {
    func makeVirtualJoysticlMovable(leftControlView leftControlView: JoystickView,
                                                    rightControlView: JoystickView) {
        
        leftControlView.rx_observe(Float.self, "xValue").asObservable()
            .flatMap { return self.drone.yaw($0!) } // tourner
            .subscribeNext {
                
        }.addDisposableTo(disposeBag)
        
        leftControlView.rx_observe(Float.self, "yValue").asObservable()
            .flatMap { return self.drone.gaz($0!) } // hauteur
            .subscribeNext {
                
        }.addDisposableTo(disposeBag)
        
        rightControlView.rx_observe(Float.self, "xValue").asObservable()
            .flatMap { return self.drone.roll($0!) }
            .subscribeNext {
                
        }.addDisposableTo(disposeBag)
        
        rightControlView.rx_observe(Float.self, "yValue").asObservable()
            .flatMap { return self.drone.pitch($0!) }
            .subscribeNext {
                
        }.addDisposableTo(disposeBag)
    }
}