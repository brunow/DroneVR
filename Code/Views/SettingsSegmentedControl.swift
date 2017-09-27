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
import RxSwift

class SettingsSegmentedControl: UIView {
    
    @IBInspectable var text: String? {
        get {
            return textLabel.text
        }
        set {
            textLabel.text = newValue
        }
    }
    
    var titles: [String]? {
        didSet {
            updateButtons()
        }
    }
    
    let selectedIndex = Variable(0)
    
    private let textLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textColor = Color(named: .SettingsTextColor)
        label.textAlignment = .Left
        label.font = Font(font: FontFamily.SFUIDisplay.Regular, size: 16)
        return label
    }()
    
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .Horizontal
        stackView.distribution = .FillEqually
        return stackView
    }()
    
    private let backgroundView: UIImageView = {
        let view = UIImageView()
        view.image = Image(asset: .SettingsSegmentedBorder)
        view.userInteractionEnabled = true
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
        layout()
    }
    
    convenience init(text: String, titles: [String]) {
        self.init(frame: .zero)
        
        self.titles = titles
        self.text = text
        
        updateButtons()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setup()
        layout()
    }
    
    override func intrinsicContentSize() -> CGSize {
        return CGSize(width: frame.width, height: 34 + textLabel.intrinsicContentSize().height + 4)
    }
    
    func setup() {
        addSubview(textLabel)
        addSubview(backgroundView)
        backgroundView.addSubview(stackView)
    }
    
    func layout() {
        textLabel <- [
            Left(),
            Right(),
            Top()
        ]
        
        backgroundView <- [
            Bottom(),
            Left(),
            Right(),
            Height(34)
        ]
        
        stackView <- Edges(3)
    }
    
    func buttonAction(sender: UIButton) {
        selectButton(sender)
        selectedIndex.value = buttons().indexOf(sender)!
    }
    
    private func selectButton(button: UIButton) {
        if !button.selected {
            for btn in buttons() {
                btn.selected = false
            }
            button.selected = true
        }
    }
    
    private func buttons() -> [UIButton] {
        return stackView.arrangedSubviews as! [UIButton]
    }
    
    private func updateButtons() {
        guard let titles = titles else { return }
        
        for view in stackView.arrangedSubviews {
            stackView.removeArrangedSubview(view)
        }
        
        let buttons: [UIButton] = titles.map { title in
            let btn = UIButton()
            btn.adjustsImageWhenHighlighted = false
            btn.setTitle(title, forState: .Normal)
            btn.setTitleColor(Color(named: .HudText), forState: .Normal)
            btn.setTitleColor(UIColor.whiteColor(), forState: .Selected)
            btn.titleLabel?.font = FontFamily.SFUIDisplay.Regular.font(13)
            btn.setBackgroundImage(Image(asset: .SettingsSegmentedUnSelectedBG), forState: .Normal)
            btn.setBackgroundImage(Image(asset: .SettingsSegmentedSelectedBG), forState: .Selected)
            btn.addTarget(self, action: #selector(SettingsSegmentedControl.buttonAction(_:)), forControlEvents: .TouchUpInside)
            return btn
        }
        
        for btn in buttons {
            stackView.addArrangedSubview(btn)
        }
    }
    
}
