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

private let sharedApplication = Application()

class Application {
    
    class func colorForBattery(level: Int, vrMode: Bool = false) -> UIColor {
        switch level {
        case 0...30:
            return Color(named: .LowBatttery)
        case 31...50:
            return Color(named: .MiddleBattery)
        default:
            if vrMode {
                return Color(named: .FlyHUDVRText)
            }
            
            return Color(named: .HighBattery)
        }
    }
    
    class func imageForBattery(level: Int) -> UIImage {
        switch level {
        case 0...30:
            return Image(asset: .LowBattery)
        case 31...50:
            return Image(asset: .MiddleBattery)
        default:
            return Image(asset: .HighBattery)
        }
    }
    
    class func applyHudVRLabelShadow(label: UILabel) {
        label.shadowColor = UIColor.blackColor()
        label.shadowOffset = CGSize(width: 0.5, height: 0.5)
    }
    
    class func configureVRLabelImageView(imageView: UIImageView) {
        imageView.tintColor = Color(named: .FlyHUDVRText)
        imageView.layer.shadowColor = UIColor.blackColor().CGColor
        imageView.layer.shadowOffset = CGSize(width: 0.5, height: 0.5)
        imageView.layer.shadowOpacity = 0.9
        imageView.layer.shadowRadius = 0
        imageView.clipsToBounds = false
    }
    
    struct Notifications {
    }
    
    class func appearance() {
        UISwitch.appearance().onTintColor = Color(named: .SwitchColor)
    }
    
    class func shared() -> Application {
        return sharedApplication
    }
    
}