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
import UIKit

protocol VideoPresentable: class {
    func makeVideoPresentable()
    func configureVideoDecoder(decoder: ARCONTROLLER_Stream_Codec_t) -> Bool
    func didReceiveVideoFrame(frame: UnsafeMutablePointer<ARCONTROLLER_Frame_t>) -> Bool
    func diReceiveVideoImage(image: UIImage)
}

extension VideoPresentable where Self:Dronable, Self:Disposable {
    func makeVideoPresentable() {
        drone.didReceiveFrameBlock = { [weak self] frame in
            guard let _self = self else { return false }
            return _self.didReceiveVideoFrame(frame)
        }
        
        drone.configureDecoderBlock = { [weak self] decoder in
            guard let _self = self else { return false }
            return _self.configureVideoDecoder(decoder)
        }
        
        drone.cameraImageObserver().subscribeNext { [weak self] image in
            guard let _self = self else { return }
            _self.diReceiveVideoImage(image)
            
        }.addDisposableTo(disposeBag)
    }
}