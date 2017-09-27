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
import ManualLayout
import RxSwift

let AlertViewHideAllNotificationKey = "AlertViewHideAllNotificationKey"

class AlertView: UIViewController {
    
    struct Settings {
        var fullscreen = true
        var backgroundColor = UIColor.whiteColor()
        var title: String? = nil
        var message: String? = nil
        var buttons: [String]? = nil
        weak var viewController: UIViewController? = nil
        var loading = false
        
        init(title: String?, message: String?, buttons: [String]?, viewController: UIViewController) {
            self.title = title
            self.message = message
            self.buttons = buttons
            self.viewController = viewController
        }
    }
    
    let disposeBag = DisposeBag()
    typealias TouchHandler = (AlertView, Int) -> ()
    
    var settings: Settings!
    
    var touchHandler: TouchHandler?
    
    private lazy var backgroundView: FXBlurView = {
        let backgroundView = FXBlurView(frame: self.view.bounds)
        backgroundView.tintColor = UIColor(r: 200, g: 200, b: 200, a: 0.9)
        backgroundView.blurRadius = 20
        backgroundView.addGestureRecognizer(self.tapOutsideTouchGestureRecognizer)
        return backgroundView
    }()
    
    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textAlignment = NSTextAlignment.Center
        titleLabel.textColor = UIColor.blackColor()
        titleLabel.font = UIFont.boldSystemFontOfSize(16)
        return titleLabel
    }()
    
    private lazy var messageLabel: UILabel = {
        let messageLabel = UILabel()
        
        messageLabel.textAlignment = NSTextAlignment.Center
        messageLabel.numberOfLines = 0
        messageLabel.textColor = UIColor.blackColor()
        messageLabel.font = UIFont.systemFontOfSize(14)
        return messageLabel;
    }()
    
    private var alertView = UIView()
    private var buttons: Array<UIButton>!
    
    private var tapOutsideTouchGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer()
    
    convenience init(title: String, message: String?, buttons: Array<String>?, viewController: UIViewController) {
        let settings = Settings(title: title, message: message, buttons: buttons, viewController: viewController)
        self.init(settings: settings)
    }
    
    init(settings: Settings) {
        super.init(nibName: nil, bundle: nil)
        
        self.settings = settings
        
        self.setupViews()
        self.setupButtons()
        self.setupLayouts()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    class func hideAll() {
        NSNotificationCenter.defaultCenter().postNotificationName(AlertViewHideAllNotificationKey, object: nil)
    }
    
    override func viewWillLayoutSubviews() {
        self.setupLayouts()
    }
    
    func show() {
        AlertView.hideAll()
        
        self.view.alpha = 0
        
        self.willMoveToParentViewController(settings.viewController!)
        settings.viewController!.addChildViewController(self)
        self.didMoveToParentViewController(settings.viewController!)
        self.settings.viewController!.view.addSubview(self.view)
        self.backgroundView.underlyingView = self.settings.viewController!.view
        
        if settings.fullscreen {
            self.view <- [
                Edges()
            ]
        } else {
            self.view <- [
                Width(400),
                Height(100),
                Center()
            ]
        }
        
        UIView.animateWithDuration(0.3) { () -> Void in
            self.view.alpha = 1
        }
    
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AlertView.hide), name: AlertViewHideAllNotificationKey, object: nil)
    }
    
    func hide() {
        self.willMoveToParentViewController(nil)
        
        let completion = { (complete: Bool) -> Void in
            if complete {
                self.view.removeFromSuperview()
                self.removeFromParentViewController()
                self.didMoveToParentViewController(nil)
            }
        }
        
        UIView.animateWithDuration(0.3,
                                   animations: { () -> Void in
                                    self.view.alpha = 0
            }, completion: completion)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        setupLayouts()
    }
}

// MARK: Private
extension AlertView {
    
    func didPressButton(sender: UIButton) {
        let buttonIndex = self.buttons.indexOf(sender)
        
        if (self.touchHandler != nil) {
            self.touchHandler!(self, buttonIndex!)
        }
        
        self.hide()
    }
    
    func setupViews() {
        self.tapOutsideTouchGestureRecognizer.addTarget(self, action: #selector(AlertView.hide))

        self.view.addSubview(self.backgroundView)
        self.view.addSubview(self.alertView)
        self.alertView.addSubview(self.titleLabel)
        self.alertView.addSubview(self.messageLabel)
        
        self.titleLabel.text = settings.title
        self.messageLabel.text = settings.message
        
        self.backgroundView.hidden = !settings.fullscreen
    }
    
    func setupLayouts() {
        let xPadding: CGFloat = 33
        
        self.alertView.left = xPadding
        self.alertView.width = self.width - self.alertView.left*2
        
        self.titleLabel.width = self.alertView.width
        self.titleLabel.height = self.titleLabel.sizeToFit(self.titleLabel.width, 500).height
        self.titleLabel.height += 16*2

        self.messageLabel.left = 12
        self.messageLabel.width = self.alertView.width - self.messageLabel.left*2
        self.messageLabel.height = self.messageLabel.sizeToFit(self.messageLabel.width, 500).height
        self.messageLabel.top = self.titleLabel.bottom + 16
        
        let buttonHeight: CGFloat = 48
        var idx = 0
        
        for button in self.buttons {
            button.height = buttonHeight
            button.width = self.alertView.width / CGFloat(self.buttons.count)
            button.top = self.messageLabel.bottom + 16
            button.left = button.width * CGFloat(idx)
            idx += 1
        }

        var totalHeight: CGFloat = self.messageLabel.bottom + 16
        let hasButton = self.buttons.count > 0
        
        if hasButton {
            totalHeight += buttonHeight
        }
        
        self.alertView.height = totalHeight
        self.alertView.centerX = self.width/2
        self.alertView.centerY = self.height/2
        
        self.backgroundView.frame = self.bounds
        
//        self.titleLabel <- [
//            Top(5),
//            Left(sideMargin),
//            Right(sideMargin)
//        ]
//        
//        self.messageLabel <- [
//            Top(10).to(self.titleLabel, .Bottom),
//            Left(sideMargin),
//            Right(sideMargin)
//        ]
//        
//        for button in self.buttons {
//            button <- [
//                Top(10).to(self.messageLabel, .Bottom)
//            ]
//        }
//        
//        self.alertView <- [
//            Left(30),
//            Right(30),
//            Height(300)
////            Height().like(self.buttons.last!, .Bottom)
//        ]
        
        self.titleLabel.backgroundColor = UIColor.lightGrayColor()
//        self.titleLabel.text = "dsdssd"
        
        self.alertView.backgroundColor = UIColor.redColor()
//        self.backgroundView.backgroundColor = UIColor.lightGrayColor()
    }
    
    func setupButtons() {
        self.buttons = []
        
        guard let buttonTitles = self.settings.buttons else { return }
        
        for title in buttonTitles {
            let button = UIButton(type: .Custom)
            button.setTitle(title, forState: .Normal)
            button.sizeToFit()
            button.addTarget(self, action: #selector(AlertView.didPressButton(_:)), forControlEvents: .TouchUpInside)
            self.alertView.addSubview(button)
            self.buttons.append(button)
        }
    }
    
}

