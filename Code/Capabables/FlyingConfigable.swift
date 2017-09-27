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

enum FlyingSpeed: String {
    case Slow
    case Normal
    case Fast
    
    func localizedString() -> String {
        return NSLocalizedString(self.rawValue.lowercaseString, comment: "")
    }
    
    mutating func next() {
        switch(self) {
        case .Slow:
            self = .Normal
            break
        case .Normal:
            self = .Fast
            break
        case .Fast:
            self = .Slow
            break
        }
    }
}

enum FlyingDistance: String {
    case Near
    case Normal
    case Far
    
    func localizedString() -> String {
        return NSLocalizedString(self.rawValue.lowercaseString, comment: "")
    }
    
    mutating func next() {
        switch(self) {
        case .Near:
            self = .Normal
            break
        case .Normal:
            self = .Far
            break
        case .Far:
            self = .Near
            break
        }
    }
}

protocol FlyingConfigable: class {
    func makeConfigable(config: DroneConfigViewModel)
}

extension FlyingConfigable where Self:Dronable, Self:Disposable {
    
    func makeConfigable(config: DroneConfigViewModel) {
        let drone = self.drone
        let configSpeedObservable = config.speed.asObservable()
        let configDistanceObservable = config.distance.asObservable()
        
        let shouldUpdateConfig =
            self.shouldUpdateConfigObservable(drone,
                                              configSpeedObservable: configSpeedObservable,
                                              configDistanceObservable: configDistanceObservable)
        
        shouldUpdateConfig
            .flatMap{ [unowned self] _ in self.sendConfig(drone, config: config) }
            .subscribeNext { _ in
                
            }.addDisposableTo(disposeBag)
    }
    
    private func shouldUpdateConfigObservable(drone: PADroneViewModel,
                                      configSpeedObservable: Observable<FlyingSpeed>,
                                      configDistanceObservable: Observable<FlyingDistance>) -> Observable<Void> {
        
        let connectionObservable = drone.connectionState.asObservable()
        let didReceiveAllConfigObservable = drone.didReceiveAllSettings.asObservable().distinctUntilChanged()
        let shouldUpdateConfig = Observable.combineLatest(connectionObservable, configSpeedObservable, configDistanceObservable, didReceiveAllConfigObservable) { connection, speed, distance, didReceiveAllConfig -> DroneConnectionState in
            return connection
        }
        
        return shouldUpdateConfig
            .filter{ $0 == DroneConnectionState.Connected && drone.hasReceivedAllSettings() }
            .map { _ in () }
    }
    
    private func sendConfig(drone: PADroneViewModel, config: DroneConfigViewModel) -> Observable<Void> {
        let droneSettings = config.droneSettings(drone.minSettings, max: drone.maxSettings)
        return drone.sendSettings(droneSettings, returnHomeDelay: 60)
    }
    
}