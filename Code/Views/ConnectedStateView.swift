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
import TextAttributes
import ManualLayout

class ConnectedStateView: UIImageView {
    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        return label
    }()
    
    lazy var connectingLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.text = "Connecting..."
        label.textColor = Color(named: .Text)
        label.textAlignment = .Center
        label.font = Font(font: FontFamily.SFUIDisplay.Regular, size: 14)
        return label
    }()
    
    lazy var connectedImageView: UIImageView = {
        let image = UIImageView(image: UIImage(asset: .ConnectedState))
        return image
    }()
    
    var name: String? {
        didSet {
            if let name = name {
                let connectedAttrs = TextAttributes()
//                    .font(name: "HelveticaNeue", size: 14)
                    .font(name: FontFamily.SFUIDisplay.Regular.rawValue, size: 14)
                    .foregroundColor(UIColor.whiteColor())
                    .alignment(.Center)
                
                let nameAttrs = TextAttributes()
//                    .font(name: "HelveticaNeue", size: 14)
                    .font(name: FontFamily.SFUIDisplay.Regular.rawValue, size: 14)
                    .foregroundColor(UIColor.whiteColor())
                    .alignment(.Center)
                
                let connectedAttributedText = NSAttributedString(string: "connected to\n", attributes: connectedAttrs)
                let nameAttributedText = NSAttributedString(string: name, attributes: nameAttrs)
                
                let attributedText = NSMutableAttributedString(attributedString: connectedAttributedText)
                attributedText.appendAttributedString(nameAttributedText)
                
                self.nameLabel.attributedText = attributedText
                self.setNeedsLayout()
                
            } else {
                self.nameLabel.attributedText = nil
            }
        }
    }
    
    init() {
        super.init(image: UIImage(asset: .MainLogo))
        self.contentMode = .ScaleAspectFit
        
        self.addSubViews([self.nameLabel, self.connectedImageView, self.connectingLabel])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.connectedImageView.centerX = self.width / 2;
        self.connectedImageView.centerY = self.height / 4.7
        
        self.nameLabel.width = self.width / 2.1
        self.nameLabel.height = self.nameLabel.sizeToFit(self.nameLabel.width, 500).height
        self.nameLabel.centerY = self.height * 0.75
        self.nameLabel.centerX = self.width / 2
        
        self.connectingLabel.width = self.nameLabel.width
        self.connectingLabel.height = self.connectingLabel.sizeToFit(self.connectingLabel.width, 500).height
        self.connectingLabel.width = self.width / 2.1
        self.connectingLabel.center = self.nameLabel.center
    }
}
