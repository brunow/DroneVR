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
import SwiftyUserDefaults
import RxSwift

class DroneConfigViewModel {
    
    private let disposeBag = DisposeBag()
    
    var speed: Variable<FlyingSpeed> = Variable(FlyingSpeed.Slow)
    var distance: Variable<FlyingDistance> = Variable(FlyingDistance.Near)
    var fpvMode: Variable<Bool> = Variable(false)
    var leftHanded: Variable<Bool> = Variable(false)
    
    init() {
        if Defaults.hasKey(.flyingSpeed) {
            self.speed.value = Defaults[.flyingSpeed]!
        }
        
        if Defaults.hasKey(.flyingDistance) {
            self.distance.value = Defaults[.flyingDistance]!
        }
        
        if Defaults.hasKey(.fpvMode) {
            self.fpvMode.value = Defaults[.fpvMode]!
        }
        
        if Defaults.hasKey(.leftHanded) {
            self.leftHanded.value = Defaults[.leftHanded]!
        }
        
        fpvMode.asObservable().subscribeNext {
            Defaults[.fpvMode] = $0
            
        }.addDisposableTo(disposeBag)
        
        leftHanded.asObservable().subscribeNext {
            Defaults[.leftHanded] = $0
            
        }.addDisposableTo(disposeBag)
        
        speed.asObservable().subscribeNext {
            Defaults[.flyingSpeed] = $0
            
        }.addDisposableTo(disposeBag)
        
        distance.asObservable().subscribeNext {
            Defaults[.flyingDistance] = $0
            
        }.addDisposableTo(disposeBag)
    }
    
    func toggleSpeedType() -> Observable<Void> {
        return Observable.create { [unowned self] observer in
            self.speed.value.next()
            
            observer.onNext()
            observer.onCompleted()
            
            return NopDisposable.instance
        }
    }
    
    func toggleDistanceType() -> Observable<Void> {
        return Observable.create { [unowned self] observer in
            self.distance.value.next()
            
            observer.onNext()
            observer.onCompleted()
            
            return NopDisposable.instance
        }
    }
    
    func droneSettings(min: DroneMetrics, max: DroneMetrics) -> DroneMetrics {
        guard min.hasAllSettings() else {
            return min
        }
        
        var settings = DroneMetrics()
        
        switch self.speed.value {
        case .Slow:
            settings.rotationSpeed = min.rotationSpeed
            settings.verticalSpeed = min.verticalSpeed
            settings.maxTilt = min.maxTilt
        case .Normal:
            settings.rotationSpeed = (max.rotationSpeed! - min.rotationSpeed!) / 2 + min.rotationSpeed!
            settings.verticalSpeed = (max.verticalSpeed! - min.verticalSpeed!) / 2 + min.verticalSpeed!
            settings.maxTilt = (max.maxTilt! - min.maxTilt!) / 2 + min.maxTilt!
        case .Fast:
            settings.rotationSpeed = max.rotationSpeed
            settings.verticalSpeed = max.verticalSpeed
            settings.maxTilt = max.maxTilt
        }
        
        switch self.distance.value {
        case .Near:
            settings.maxAltitude = min.maxAltitude
            settings.maxDistance = min.maxDistance
        case .Normal:
            settings.maxAltitude = 40
            settings.maxDistance = 200
        case .Far:
            settings.maxAltitude = max.maxAltitude
            settings.maxDistance = max.maxDistance
        }
        
        return settings
    }
}

extension DefaultsKeys {
    static let flyingSpeed = DefaultsKey<FlyingSpeed?>("flyingSpeed")
    static let flyingDistance = DefaultsKey<FlyingDistance?>("flyingDistance")
    static let leftHanded = DefaultsKey<Bool?>("leftHanded")
    static let fpvMode = DefaultsKey<Bool?>("fpvMode")
}

extension NSUserDefaults {
    subscript(key: DefaultsKey<FlyingSpeed?>) -> FlyingSpeed? {
        get { return unarchive(key) }
        set { archive(key, newValue) }
    }
}

extension NSUserDefaults {
    subscript(key: DefaultsKey<FlyingDistance?>) -> FlyingDistance? {
        get { return unarchive(key) }
        set { archive(key, newValue) }
    }
}
