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

class MenuView: UIView {
    
    let closeBtn:HudRoundedButton = HudRoundedButton(type: .Close)
    
    let emergencyBtn = HudRoundedButton(type: .Emergency)
    
    let simpleMenuStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.alignment = .Center
        stackView.axis = .Horizontal
        stackView.spacing = 32
        stackView.distribution = .FillEqually
        return stackView
    }()
    
    let menuStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.alignment = .Center
        stackView.axis = .Horizontal
        stackView.spacing = 32
        stackView.distribution = .FillProportionally
        return stackView
    }()
    
    private let centeringStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.alignment = .Center
        stackView.axis = .Vertical
        stackView.spacing = 32
        stackView.distribution = .FillProportionally
        return stackView
    }()
    
    private let backgroundView = UIImageView(image: Image(asset: .HomeBackground))
    
    private let blurView: FXBlurView = {
        let view = FXBlurView()
        view.tintColor = UIColor(r: 0, g: 0, b: 0, a: 1)
        view.blurRadius = 20
//        view.updateInterval = 0.1
        view.dynamic = false
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
        backgroundColor = UIColor.clearColor()
        
        backgroundView.contentMode = .ScaleAspectFill
        
        addSubview(backgroundView)
        backgroundView.addSubview(blurView)
        addSubview(closeBtn)
        addSubview(emergencyBtn)
        addSubview(centeringStackView)
        
        centeringStackView.addArrangedSubview(menuStackView)
        centeringStackView.addArrangedSubview(simpleMenuStackView)
        
//        blurView.underlyingView = backgroundView
    }
    
    func layout() {
        blurView <- Edges()
        backgroundView <- Edges()
        
        emergencyBtn <- [
            Top(9),
            CenterX()
        ]
        
        closeBtn <- [
            Top(9),
            Right(9)
        ]
        
        centeringStackView <- [
            Left(10),
            Right(10),
            CenterY()
        ]
        
    }
    
}