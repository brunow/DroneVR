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
import EasyPeasy

class FlyingMetricsView: UIView {
    
    var altitude: String = "" {
        didSet {
            self.altitudeLabel.text = altitude
        }
    }
    
    var distance: String = "" {
        didSet {
            self.distanceLabel.text = distance
        }
    }
    
    var speed: String = "" {
        didSet {
            self.speedLabel.text = speed
        }
    }
    
    private let altitudeLabel = UILabel()
    private let distanceLabel = UILabel()
    private let speedLabel = UILabel()
    private let distanceIconView = UIImageView(image: UIImage(asset: .DistanceIcon))
    private let altitudeIconView = UIImageView(image: UIImage(asset: .AltitudeIcon))
    private let speedSepIconView = UIImageView(image: UIImage(asset: .LineSep))
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.distanceLabel.font = Fonts.HUDMetrics
        self.altitudeLabel.font = Fonts.HUDMetrics
        self.speedLabel.font = Fonts.HUDMetrics
        
        self.distanceLabel.textColor = Color(named: .FlyHUDText)
        self.altitudeLabel.textColor = Color(named: .FlyHUDText)
        self.speedLabel.textColor = Color(named: .FlyHUDText)
        
        self.addSubViews([self.altitudeLabel, self.distanceLabel, self.speedLabel, self.altitudeLabel, self.distanceIconView, self.altitudeIconView, self.speedSepIconView])
        
        self.layout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
  
    override func intrinsicContentSize() -> CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: self.distanceLabel.font.pointSize)
    }
    
    func layout() {
        distanceIconView <- [
            Left(),
            CenterY()
        ]
        
        distanceLabel <- [
            Left(4).to(distanceIconView, .Right),
            CenterY()
        ]
        
        altitudeIconView <- [
            Left(8).to(distanceLabel, .Right),
            CenterY()
        ]
        
        altitudeLabel <- [
            Left(4).to(altitudeIconView, .Right),
            CenterY()
        ]
        
        speedSepIconView <- [
            Left(8).to(altitudeLabel, .Right),
            CenterY()
        ]
        
        speedLabel <- [
            Left(8).to(speedSepIconView, .Right),
            CenterY()
        ]
    }
    
}
