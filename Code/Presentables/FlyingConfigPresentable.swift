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

protocol FlyingConfigPresentable: class {
    func makeFlyingConfigPresentable(config: DroneConfigViewModel)
    
    func didChangeDistanceConfig(title: String)
    func didChangeSpeedConfig(title: String)
}

extension FlyingConfigPresentable where Self:Disposable {
    func makeFlyingConfigPresentable(config: DroneConfigViewModel) {
        config.distance.asDriver().driveNext { [unowned self] distance in
            let title = "\(distance.localizedString()) distance"
            self.didChangeDistanceConfig(title)
        }.addDisposableTo(disposeBag)
        
        config.speed.asDriver().driveNext { [unowned self] speed in
            let title = "\(speed.localizedString()) speed"
            self.didChangeSpeedConfig(title)
        }.addDisposableTo(disposeBag)
    }
}