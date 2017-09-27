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

class SettingsBoolean: UIView {
    
    struct Constants {
        static let sep: CGFloat = 5
    }
    
    var view: UIView!
    
    @IBInspectable var text: String? {
        get {
            return textLabel.text
        }
        set {
            textLabel.text = newValue
        }
    }
    
    @IBInspectable var detail: String? {
        get {
            return detailTextLabel.text
        }
        set {
            detailTextLabel.text = newValue
        }
    }
    
    let textLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textColor = Color(named: .SettingsTextColor)
        label.textAlignment = .Left
        label.font = Font(font: FontFamily.SFUIDisplay.Regular, size: 16)
        return label
    }()
    
    let detailTextLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = Color(named: .SettingsTextColor)
        label.textAlignment = .Left
        label.font = Font(font: FontFamily.SFUIDisplay.Light, size: 13)
        return label
    }()
    
    let switchView: UISwitch = {
        let view = UISwitch()
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
        layout()
    }
    
    convenience init(text: String, detail: String? = nil) {
        self.init(frame: .zero)
        
        self.detail = detail
        self.text = text
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setup()
        layout()
    }
    
    func setup() {
        addSubview(textLabel)
        addSubview(detailTextLabel)
        addSubview(switchView)
        
//        switchView.tintColor = UIColor.whiteColor()
//        switchView.layer.cornerRadius = 16
//        switchView.backgroundColor = UIColor.whiteColor()
        
        backgroundColor = UIColor.clearColor()
    }
    
//    override func intrinsicContentSize() -> CGSize {
//        var height: CGFloat = switchView.intrinsicContentSize().height
//        
//        if detail != nil {
//            height += detailTextLabel.intrinsicContentSize().height + Constants.sep
//        }
//        
//        return CGSize(width: frame.width, height: height)
//    }
    
    func layout() {
        switchView <- [
            Top(),
            Right()
        ]
        
        textLabel <- [
            Left(),
            CenterY().to(switchView, .CenterY),
            Right(10).to(switchView, .Left)
        ]
        
        detailTextLabel <- [
            Left(),
            Right().to(textLabel, .Right),
            Top(2).to(textLabel, .Bottom),
            Bottom()
        ]
    }
    
}
