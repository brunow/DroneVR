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
import RxCocoa
import ManualLayout
import EasyPeasy

class FlyingViewGlassesHud: UIView {
    
    let backgroundImageView = UIImageView(image: UIImage(named: "HomeBackground"))
    let videoView = PABebopVideoView()
    let gpsLabel = UILabel()
    let cameraHorizont = FlyingCameraHorizont()
    
    let hud = GlassesInformationsHud()
    
    var leftSide = false {
        didSet {
            maskView = nil
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        gpsLabel.text = "Acquiring GPS"
        gpsLabel.textColor = Color(named: .FlyBadGPS)
        gpsLabel.font = Fonts.HUDMetrics
        
        addSubViews([backgroundImageView, videoView, cameraHorizont, gpsLabel, hud])
        
        let top = UIView()
        top.backgroundColor = .blackColor()
        
        let bottom = UIView()
        bottom.backgroundColor = .blackColor()
        
        hud <- [
            Left(30),
            Top(),
            Right(30),
            Bottom()
        ]
        
        backgroundImageView <- Edges()
        cameraHorizont <- Edges()
        videoView <- Edges()
        
//        maskImage <- [
//            Center()
//        ]
        
//        addSubview(top)
//        addSubview(bottom)
//        
//        top <- [
//            Left(),
//            Top(),
//            Right().to(self, .Right),
//            Height(80)
//        ]
//        
//        bottom <- [
//            Left(),
//            Bottom(),
//            Right().to(self, .Right),
//            Height().like(top, .Height)
//        ]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if nil == maskView {
            let maskImageView = UIImageView(image: maskImage())
            maskView = maskImageView
        }
        
        self.gpsLabel.sizeToFit()
        self.gpsLabel.height = 25
        self.gpsLabel.centerX = self.width/2
    }
    
    func maskImage() -> UIImage {
        let mask = leftSide ? Image(asset: .MaskImageLeft) : Image(asset: .MaskImageRight)
        
        let width = size.width
        let height: CGFloat = 200
        let y = size.height / 2 - height / 2
        let x: CGFloat = leftSide ? -20 : 20
        
        UIGraphicsBeginImageContextWithOptions(size, false, 1)
        mask.drawInRect(CGRect(x: x, y: y, width: width, height: height))
        
        let screenshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return screenshot
    }

}
