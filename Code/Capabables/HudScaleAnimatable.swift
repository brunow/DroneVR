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
import RxSwift

protocol HudScaleAnimatable: class {
    func makeAnimatable()
    func animateUp()
    func animateDown()
    func cancelAnimate()
}

extension HudScaleAnimatable where Self:UIButton, Self:Disposable {
    
    func makeAnimatable() {
        adjustsImageWhenHighlighted = false
        
        rx_controlEvent(.TouchUpInside).subscribeNext { [weak self] _ in
            guard let _self = self else { return }
            _self.animateUp()
        }.addDisposableTo(disposeBag)
        
        rx_controlEvent(.TouchDown).subscribeNext { [weak self] _ in
            guard let _self = self else { return }
            _self.animateDown()
        }.addDisposableTo(disposeBag)
        
        rx_controlEvent(.TouchCancel).subscribeNext { [weak self] _ in
            guard let _self = self else { return }
            _self.cancelAnimate()
        }.addDisposableTo(disposeBag)
    }
    
    func cancelAnimate() {
        animate {
            self.transform = CGAffineTransformIdentity
            }
            .withSpring(dampingRatio: 0.5, initialVelocity: 0)
    }
    
    func animateUp() {
        animate {
            self.transform = CGAffineTransformIdentity
        }
        .withSpring(dampingRatio: 0.5, initialVelocity: 0)
    }
    
    func animateDown() {
        animate {
            self.scale(sx: 0.9, sy: 0.9)
        }
        .withSpring(dampingRatio: 0.5, initialVelocity: 0)
    }

}