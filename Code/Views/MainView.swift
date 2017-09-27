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
//import ManualLayout
import TextAttributes
import EasyPeasy

class MainView: UIView {
    let connectedStateImage = ConnectedStateView()
    let flyBtn = FlyButton()
    
    lazy var supportBtn: UIButton = {
        let btn = UIButton(type: .Custom)
        let attrs = TextAttributes()
            .font(name: FontFamily.SFUIDisplay.Regular.rawValue, size: 14)
            .foregroundColor(UIColor.whiteColor())
            .lineHeightMultiple(1.5)
            .underlineStyle(.StyleSingle)
        
        let attributedString = NSAttributedString(string: "Support", attributes: attrs)
        btn.setAttributedTitle(attributedString, forState: .Normal)
        return btn
    }()
    
    lazy var findDroneBtn: UIButton = {
        let btn = UIButton(type: .Custom)
        let attrs = TextAttributes()
            .font(name: FontFamily.SFUIDisplay.Regular.rawValue, size: 14)
            .foregroundColor(UIColor.whiteColor())
            .lineHeightMultiple(1.5)
            .underlineStyle(.StyleSingle)
        
        let attributedString = NSAttributedString(string: "Find my drone", attributes: attrs)
        btn.setAttributedTitle(attributedString, forState: .Normal)
        return btn
    }()
    
    let backgroundImageView = UIImageView(image: UIImage(asset: .HomeBackground))

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setup()
        self.layout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        self.addSubViews([self.backgroundImageView, self.flyBtn, self.connectedStateImage, self.supportBtn, findDroneBtn])
    }
    
    func layout() {
        self.backgroundImageView <- Edges()
        
        self.supportBtn <- [
            CenterX(),
            Bottom(20).to(self, .Bottom)
        ]
        
        findDroneBtn <- [
            Bottom(20).to(self, .Bottom),
            Right(20)
        ]
        
        self.flyBtn <- [
            CenterX(),
            Bottom(20).to(self.supportBtn, .Top),
            Width(>=120)
        ]
        
        self.connectedStateImage <- [
            CenterX(),
            Top(44),
            Bottom(34).to(self.flyBtn, .Top),
//            Width().like(self.connectedStateImage, .Height).with(.LowPriority)
        ]
    }

}
