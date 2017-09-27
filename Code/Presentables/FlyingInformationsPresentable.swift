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

protocol FlyingInformationsPresentable: class {
    func makeFlyingInformationsPresentable()
    
    func didUpdateBattery(level: Int, lowPower: Bool)
    func didUpdateHorizontalSpeed(speed: String)
    func didUpdateAltitude(altitude: String)
    func didUpdateDistance(distance: String)
    func didUpdateGpsSafety(safe: Bool)
    func didUpdateRecordingState(recording: Bool)
    func didUpdateStayingState(flying: Bool)
}

extension FlyingInformationsPresentable where Self:Disposable, Self:Dronable {
    func makeFlyingInformationsPresentable() {
        drone.battery.asDriver().driveNext { [weak self] battery in
            guard let _self = self else { return }
            _self.didUpdateBattery(battery, lowPower: battery < 30)
        }.addDisposableTo(disposeBag)
        
        drone.horizontalSpeed.asDriver().driveNext { [weak self] speed in
            guard let _self = self else { return }
            let stringSpeed = "\(Int(speed*3.6)) km/h"
            _self.didUpdateHorizontalSpeed(stringSpeed)
        }.addDisposableTo(disposeBag)
        
        self.drone.altitude.asDriver().driveNext { [weak self] altitude in
            guard let _self = self else { return }
            let stringAltitude = "\(Int(altitude)) m"
            _self.didUpdateAltitude(stringAltitude)
        }.addDisposableTo(disposeBag)
        
        self.drone.distance.asDriver().driveNext { [weak self] distance in
            guard let _self = self else { return }
            let stringDistance = "\(Int(distance)) m"
            _self.didUpdateDistance(stringDistance)
        }.addDisposableTo(disposeBag)
        
        self.drone.safeGPS.asDriver().driveNext { [weak self] safeGPS in
            guard let _self = self else { return }
            _self.didUpdateGpsSafety(safeGPS)
        }.addDisposableTo(disposeBag)
        
        self.drone.recording.asDriver().driveNext { [weak self] recording in
            guard let _self = self else { return }
            _self.didUpdateRecordingState(recording)
        }.addDisposableTo(disposeBag)
        
        drone.flying.distinctUntilChanged().asDriver(onErrorJustReturn: false).driveNext { [weak self] flying in
            guard let _self = self else { return }
            _self.didUpdateStayingState(flying)
        }.addDisposableTo(disposeBag)
    }
}