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
import MapKit
import EasyPeasy

class MapView: UIView {
    
    let mapView = MKMapView()
    
    private let containerView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let navBarView: UIImageView = {
        let view = UIImageView()
        view.image = Image(asset: .FindDroneBarBG)
        view.userInteractionEnabled = true
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = Font(font: FontFamily.SFUIDisplay.Semibold, size: 17)
        label.textColor = UIColor.whiteColor()
        label.text = "Find my drone"
        return label
    }()
    
    let closeBtn: UIButton = {
        let btn = UIButton()
        btn.setImage(Image(asset: .FindDroneCloseBtn), forState: .Normal)
        return btn
    }()
    
    let distanceView = MapItemView(title: "distance")
    
    let dateView = MapItemView(title: "last known position")
    
    private let shadowedView: UIView = {
        let view = UIImageView()
        view.image = Image(asset: .MapBG)
        view.contentMode = .Redraw
        view.layer.shadowColor = UIColor.blackColor().CGColor
        view.layer.shadowOffset = CGSize(width: -3, height: 0)
        view.layer.shadowOpacity = 0.2
        view.layer.shadowRadius = 5
        view.layer.masksToBounds = false
        view.clipsToBounds = false
        return view
    }()
    
    private let directionLabel: UILabel = {
        let label = UILabel()
        label.font = Font(font: FontFamily.SFUIDisplay.Regular, size: 12)
        label.textColor = Color(named: .HudText)
        label.text = "Drone direction".uppercaseString
        return label
    }()
    
    let compassView: UIImageView = {
        let view = UIImageView()
        view.image = Image(asset: .FindDroneCompass)
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
        layout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        backgroundColor = UIColor.whiteColor()
        
        addSubview(mapView)
        addSubview(shadowedView)
        addSubview(containerView)
        
        // Container view
        containerView.addSubview(navBarView)
        containerView.addSubview(directionLabel)
        containerView.addSubview(compassView)
        containerView.addSubview(distanceView)
        containerView.addSubview(dateView)
        
        // Nav bar view
        navBarView.addSubview(titleLabel)
        navBarView.addSubview(closeBtn)
    }
    
    func layout() {
        containerView <- [
            Width(*0.35).like(self, .Width),
            Top(),
            Bottom(),
            Right()
        ]
        
        shadowedView <- [
            Size().like(containerView),
            Top(),
            Right()
        ]
        
        mapView <- [
            Left(),
            Top(),
            Bottom(),
            Right().to(containerView, .Left)
        ]
        
        navBarView <- [
            Height(44),
            Left(),
            Right(),
            Top()
        ]
        
        closeBtn <- [
            Right(8).to(self, .Right),
            CenterY()
        ]
        
        titleLabel <- [
            CenterY(),
            CenterX(),
            Right(<=0).to(closeBtn, .Left)
        ]
        
        directionLabel <- [
            CenterX(),
            Top(16).to(navBarView, .Bottom)
        ]
        
        compassView <- [
            Width(*0.4).like(containerView, .Width),
            Height().like(compassView, .Width),
            Top(16).to(directionLabel, .Bottom),
            CenterX()
        ]
        
        distanceView <- [
            Top(16).to(compassView, .Bottom),
            Left(16),
            Right(16)
        ]
        
        dateView <- [
            Top(16).to(distanceView, .Bottom),
            Left(16),
            Right(16),
            Bottom(16).to(self, .Bottom).with(.LowPriority)
        ]
    }
    
}
