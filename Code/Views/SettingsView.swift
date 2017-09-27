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

class SettingsView: UIView {
    
    let closeBtn:HudRoundedButton = HudRoundedButton(type: .Close)
    
    private let backgroundView = UIImageView(image: Image(asset: .HomeBackground))
    
    private let boxView = UIImageView()
    
    private let shadowedView = UIView()
    
    let scrollView = UIScrollView()
    
    let actionBtn = Button()
    
    convenience init() {
        self.init(frame: .zero)
        
        setup()
        layout()
    }
    
    func setup() {
        actionBtn.setTitle("Go", forState: .Normal)
        
        backgroundView.contentMode = .ScaleAspectFill
        
        boxView.layer.cornerRadius = 5
        boxView.clipsToBounds = true
        boxView.userInteractionEnabled = true
        boxView.contentMode = .ScaleAspectFill
        boxView.image = Image(asset: .SettingsBlurredBG)
        
        shadowedView.backgroundColor = .whiteColor()
        shadowedView.layer.cornerRadius = 5
        shadowedView.layer.shadowColor = UIColor(r:0, g:0, b:0, a:0.2).CGColor
        shadowedView.layer.shadowRadius = 8
        shadowedView.layer.shadowOffset = CGSize(width: 0, height: 2)
        shadowedView.layer.shadowOpacity = 1
        
        addSubview(backgroundView)
        addSubview(shadowedView)
        addSubview(boxView)
        addSubview(closeBtn)
        
        boxView.addSubview(actionBtn)
        boxView.addSubview(scrollView)
    }
    
    func layout() {
        let containerInset: CGFloat = 16
        
        backgroundView <- Edges()
        
        boxView <- [
            Width(*0.5).like(self, .Width),
            Height(*0.8).like(self, .Height),
            Center()
        ]
        
        shadowedView <- [
            Width().like(boxView, .Width),
            Height().like(boxView, .Height),
            Center()
        ]
        
        closeBtn <- [
            Top(9),
            Right(9)
        ]
        
        actionBtn <- [
            Bottom(containerInset),
            Left(containerInset),
            Right(containerInset),
            Height(44)
        ]
        
        scrollView <- [
            Top(containerInset),
            Left(containerInset),
            Right(containerInset),
            Bottom(containerInset).to(actionBtn, .Top)
        ]
    }
    
}
