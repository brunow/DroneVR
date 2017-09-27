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

class ManualSettingsView: UIView {
    
    let leftHanded = SettingsBoolean(text: "Left handed")
    
    let outdoor = SettingsBoolean(text: "Outdoor")
    
    let bankedMode = SettingsBoolean(text: "Banked mode", detail: "")
    
    let rollStabilisation = SettingsBoolean(text: "Roll stabilisation", detail: "")
    
    let fpvMode = SettingsBoolean(text: "FPV mode", detail: "Activate it for better streaming video quality")
    
    let frameRate = SettingsSegmentedControl(text: "Frame rate", titles: ["24 fps", "25 fps", "30 fps"])
    
//    let liveFacebook = SettingsBoolean(text: "Live Facebook")
    
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = 16
        stackView.axis = .Vertical
        stackView.distribution = .FillProportionally
        return stackView
    }()

    convenience init() {
        self.init(frame: .zero)
        
        setup()
        layout()
    }
    
    override func intrinsicContentSize() -> CGSize {
        return CGSize(width: frame.width, height: stackView.intrinsicContentSize().height)
    }
    
    func setup() {
        stackView.addArrangedSubview(frameRate)
        stackView.addArrangedSubview(leftHanded)
        stackView.addArrangedSubview(outdoor)
        stackView.addArrangedSubview(bankedMode)
        stackView.addArrangedSubview(rollStabilisation)
        stackView.addArrangedSubview(fpvMode)
//        stackView.addArrangedSubview(liveFacebook)
        
        addSubview(stackView)
    }
    
    func layout() {
        stackView <- Edges()
    }

}
