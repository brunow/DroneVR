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

enum MenuIconButtonType {
    case ReturnHome
    case VR
    case FindDrone
    
    func title() -> String {
        switch self {
        case .ReturnHome:
            return "Return home"
        case .VR:
            return "VR Mode"
        case .FindDrone:
            return "Find my drone"
        }
        
    }
    
    func showSwitch() -> Bool {
        switch self {
        case .ReturnHome:
            return true
        case .VR:
            return true
        default:
            return false
        }
    }
    
    func icon() -> UIImage {
        switch self {
        case .ReturnHome:
            return Image(asset: .MenuReturnHomeButton)
        case .VR:
            return Image(asset: .MenuVRButton)
        case .FindDrone:
            return Image(asset: .MenuFindMyDroneButton)
        }
    }
}

class MenuIconButton: UIControl {
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var textLabel: UILabel!
    
    @IBOutlet weak var switchView: UISwitch!
    
    var type: MenuIconButtonType? {
        didSet {
            setup()
        }
    }
    
    class func button(type: MenuIconButtonType) -> MenuIconButton {
        let btn = NSBundle.mainBundle().loadNibNamed("MenuIconButton", owner: self, options: nil).first as! MenuIconButton
        btn.type = type
        return btn
    }
    
    convenience init(title: String, type: MenuIconButtonType) {
        self.init(frame: .zero)
        
//        setTitle(title, forState: .Normal)
        
        setup()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setup()
    }
    
    override func intrinsicContentSize() -> CGSize {
        return CGSize(width: 146, height: 123)
    }
    
    private func setup() {
        if let type = type {
            textLabel.text = type.title()
            imageView.image = type.icon()
            switchView.hidden = !type.showSwitch()
        }
        
        textLabel.font = FontFamily.SFUIDisplay.Medium.font(14)
        textLabel.textColor = Color(named: .HudText)
    }
    
}
