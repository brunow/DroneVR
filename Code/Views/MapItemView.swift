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

class MapItemView: UIStackView {
    
    var value: String? {
        get {
            return valueLabel.text
        }
        set {
            valueLabel.text = newValue?.uppercaseString
        }
    }
    
    private var titleLabel: UILabel = {
        let label = UILabel()
        label.font = Font(font: FontFamily.SFUIDisplay.Regular, size: 12)
        label.textColor = Color(named: .HudText)
        return label
    }()
    
    private var valueLabel: UILabel = {
        let label = UILabel()
        label.font = Font(font: FontFamily.SFUIDisplay.Bold, size: 20)
        label.textColor = Color(named: .HudText)
        label.minimumScaleFactor = 0.7
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    convenience init(title: String) {
        self.init(frame: .zero)
        
        titleLabel.text = title.uppercaseString
        
        setup()
    }
    
    func setup() {
        axis = .Vertical
        
        addArrangedSubview(titleLabel)
        addArrangedSubview(valueLabel)
    }

}
