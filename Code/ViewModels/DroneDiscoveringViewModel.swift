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

class DroneDiscoveringViewModel: NSObject, PADroneDiscovererDelegate {
    
    private let discoverer = PADroneDiscoverer()
    private let disposeBag = DisposeBag()
    private var service: ARService?
    
    var found = Variable(false)
    
//    let didDiscoveredDrone = PublishSubject<ARService>()
    
    override init() {
        super.init()
        discoverer.delegate = self
    }
    
    deinit {
        self.stopDiscovering()
    }
    
    func startDiscovering() {
        #if Simulator
            self.found.value = true
        #else
            discoverer.startDiscovering()
        #endif
    }
    
    func stopDiscovering() {
        #if Simulator
        #else
            discoverer.stopDiscovering()
        #endif
        clearList()
    }
    
    private func clearList() {
        service = nil
        found.value = false
    }
    
    func name() -> String? {
        if let service = self.service {
            return service.name
        }
        
        #if Simulator
            return "Simulator"
        #else
            return nil
        #endif
    }
    
    func driver() -> PADriverProtocol? {
        if nil != self.service {
            switch self.service!.product {
            case (ARDISCOVERY_PRODUCT_MINIDRONE), (ARDISCOVERY_PRODUCT_MINIDRONE_EVO_BRICK):
                return PAMiniDroneDriver(service: self.service!)
                
            case (ARDISCOVERY_PRODUCT_ARDRONE), (ARDISCOVERY_PRODUCT_BEBOP_2):
                return PABeebopDriver(service: self.service!)
            default:
                break
            }
        }
        return nil
    }
    
    func drone() -> PADroneViewModel? {
        var drone: PADroneViewModel? = nil
        
        #if Simulator
            let driver = PADummyDriver()
            drone = PADroneViewModel(driver: driver)
        #else
            if nil != self.service {
                drone = PADroneViewModel(driver: self.driver()!)
            }
        #endif
        
        return drone
    }
    
    // PADroneDiscovererDelegate
    @objc func droneDiscoverer(droneDiscoverer: PADroneDiscoverer!, didUpdateDronesList dronesList: [AnyObject]!) {
        if dronesList.count > 0 {
            self.service = dronesList.first as? ARService
            if self.service != nil {
                self.found.value = true
            }
        } else {
            service = nil
            self.found.value = false
        }
    }
}
