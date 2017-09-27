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
import CoreLocation
import RxSwift
import SwiftyUserDefaults
import MapKit

class RecoveryViewModel {
    
    internal let disposeBag = DisposeBag()
    
    private static let dateFormater: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateStyle = .MediumStyle
        formatter.timeStyle = .ShortStyle
        return formatter
    }()
    
    private static let distanceFormatter: MKDistanceFormatter = {
        let formatter = MKDistanceFormatter()
        return formatter
    }()
    
    var lastStringDate: String {
        guard let date = Defaults[.date] else { return "No date" }
        return RecoveryViewModel.dateFormater.stringFromDate(date)
    }
    
    func distanceFromLocation(location: CLLocation) -> String {
        guard let droneLocation = lastLocation() else { return "" }
        let distance = droneLocation.distanceFromLocation(location)
        return RecoveryViewModel.distanceFormatter.stringFromDistance(distance)
    }
    
    func saveLocationChange(location: Observable<CLLocation?>) {
        location
            .flatMap { RecoveryViewModel.save($0) }
            .subscribeNext {
                
        }.addDisposableTo(disposeBag)
    }
    
    func lastLocation() -> CLLocation? {
        //return CLLocation(latitude: 50.769904, longitude: 4.212988)
        guard Defaults.hasKey(.latitude) && Defaults.hasKey(.longitude) else { return nil }
        return CLLocation(latitude: Defaults[.latitude]!, longitude: Defaults[.longitude]!)
    }
    
    class func hasLocation() -> Bool {
        return RecoveryViewModel().lastLocation() != nil
    }
    
}

// MARK: Private
extension RecoveryViewModel {
    
    private class func save(location: CLLocation?) -> Observable<()> {
        return Observable.create { observable in
            
            if let location = location {
                Defaults[.latitude] = location.coordinate.latitude
                Defaults[.longitude] = location.coordinate.longitude
                Defaults[.date] = NSDate()
            }
            
            observable.onNext()
            observable.onCompleted()
            return NopDisposable.instance
        }
    }
    
}

extension DefaultsKeys {
    static let latitude = DefaultsKey<CLLocationDegrees?>("recoveryLatitude")
    static let longitude = DefaultsKey<CLLocationDegrees?>("recoveryLongitude")
    static let date = DefaultsKey<NSDate?>("recoveryDate")
}

extension NSUserDefaults {
    subscript(key: DefaultsKey<CLLocationDegrees?>) -> CLLocationDegrees? {
        get { return unarchive(key) }
        set { archive(key, newValue) }
    }
}
