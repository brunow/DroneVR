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
import EasyPeasy

class FlyingNormalHud: UIView {

    let batteryView = FlyingBatteryLevelView()
    let lineBatteryView = LineBatteryLevelView()
    let backgroundImageView = UIImageView(image: UIImage(named: "HomeBackground"))
    let leftControlView = JoystickView()
    let rightControlView = JoystickView()
    let videoView = PABebopVideoView()
    let emergencyBtn = HudRoundedButton(type: .Emergency)
    let takeOffLandBtn = TakeOffButton()
    let metricsView = FlyingMetricsView()
    let metricsOverlayView = UIImageView(image: UIImage(asset: .FlyingMetricsOverlay))
    let metricsChangeView = FlyingMetricsChangeView()
    
    let moreBtn = HudRoundedButton(type: .More)
    let takePhotoBtn = HudRoundedButton(type: .Photo)
    let recordingBtn = RecordingButton()
    
    let actionButtonsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.alignment = .Top
        stackView.axis = .Horizontal
        stackView.spacing = 14
        stackView.distribution = .EqualSpacing
        return stackView
    }()
    
    let gpsLabel: UILabel = {
        let label = UILabel()
        label.text = "Acquiring GPS"
        label.textColor = Color(named: .FlyBadGPS)
        label.font = Fonts.HUDMetrics
        return label
    }()
    
    let cameraHorizont = FlyingCameraHorizont()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setup()
        self.layout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        self.addSubViews([self.backgroundImageView, self.videoView, self.cameraHorizont, self.takeOffLandBtn,
            self.batteryView, self.emergencyBtn, self.leftControlView, self.rightControlView, self.metricsOverlayView, self.lineBatteryView,
            self.metricsView, self.gpsLabel, self.metricsChangeView, self.actionButtonsStackView])
        
        self.actionButtonsStackView.addArrangedSubview(takePhotoBtn)
        self.actionButtonsStackView.addArrangedSubview(recordingBtn)
        self.actionButtonsStackView.addArrangedSubview(moreBtn)
    }
    
    func layout() {
        let padding: CGFloat = 9
        
        backgroundImageView <- Edges()
        videoView <- Edges()
        cameraHorizont <- Edges()
        
        takeOffLandBtn <- [
            CenterX(),
            Bottom(15)
        ]
        
        lineBatteryView <- [
            Bottom(),
            Width().like(self)
        ]
        
        emergencyBtn <- [
            Top(padding),
            CenterX()
        ]
        
        batteryView <- [
            Left(padding),
            CenterY().to(emergencyBtn)
        ]
        
        gpsLabel <- [
            Left(16).to(batteryView, .Right),
            CenterY().to(emergencyBtn)
        ]
        
        actionButtonsStackView <- [
            CenterY().to(emergencyBtn),
            Right(padding)
        ]
        
        metricsView <- [
            Bottom(padding),
            Left(padding)
        ]
        
        metricsOverlayView <- [
            Height(36),
            Bottom(),
            Left(0),
            Right(0)
        ]
        
        metricsChangeView <- [
            Right(padding),
            CenterY().to(metricsView, .CenterY),
            Left(10).to(takeOffLandBtn, .Right)
        ]
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let horizontalMargin: CGFloat = 60;
        let verticalMargin: CGFloat = 50;
        
        self.leftControlView.frame = CGRectMake(verticalMargin, horizontalMargin, self.width/2 - verticalMargin*2, self.height-horizontalMargin*2);
        self.rightControlView.frame = CGRectMake(self.width/2 + verticalMargin, horizontalMargin, self.width/2 - verticalMargin*2, self.height-horizontalMargin*2);
        
//        self.backgroundImageView.frame = self.bounds
//        self.videoView.frame = self.bounds
//        self.cameraHorizont.frame = self.bounds
//        
//        self.takeOffLandBtn.size =~ (100, 30)
//        self.takeOffLandBtn.right = self.width
//        self.takeOffLandBtn.centerY = self.takeOffLandBtn.height / 2
//        
//        self.emergencyBtn.size =~ (100, 30)
//        self.emergencyBtn.centerX = self.centerX
//        self.emergencyBtn.centerY = self.takeOffLandBtn.height / 2
//        self.emergencyBtn.backgroundColor = UIColor.redColor()
//        
//        self.takeOffLandBtn.backgroundColor = UIColor.redColor()
//        
//        self.batteryView.size =~ (60, 25)
//        
//        let horizontalMargin: CGFloat = 60;
//        let verticalMargin: CGFloat = 50;
//        
//        self.leftControlView.frame = CGRectMake(verticalMargin, horizontalMargin, self.width/2 - verticalMargin*2, self.height-horizontalMargin*2);
//        self.rightControlView.frame = CGRectMake(self.width/2 + verticalMargin, horizontalMargin, self.width/2 - verticalMargin*2, self.height-horizontalMargin*2);
//        
//        self.gpsLabel.sizeToFit()
//        self.gpsLabel.height = self.batteryView.height
//        self.gpsLabel.left = self.batteryView.right + 8
//        
//        self.metricsView.size =~ (140, 25)
//        self.metricsView.bottom = self.height
//        
////        self.distanceTypeBtn.sizeToFit()
//        self.distanceTypeBtn.size =~ (140, 25)
//        self.distanceTypeBtn.bottom = self.height
//        self.distanceTypeBtn.centerX = self.width/2
//        
////        self.speedTypeBtn.sizeToFit()
//        self.speedTypeBtn.size =~ (140, 25)
//        self.speedTypeBtn.right = self.width - 7
//        self.speedTypeBtn.bottom = self.distanceTypeBtn.bottom
//        
////        self.leftControlView.backgroundColor = UIColor.redColor()
////        self.rightControlView.backgroundColor = UIColor.redColor()
    }

}
