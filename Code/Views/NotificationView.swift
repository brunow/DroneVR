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

struct Notification {
    enum Status: String {
        case Error, Success, Loading
        
        func description() -> String {
            return self.rawValue
        }
    }
    
    var status: Status
    var message: String
    var viewController: UIViewController
    var cancelAction: ()? = nil
    var pressAction: ()? = nil
    var duration: NSTimeInterval? = nil
    var cancel: String? = nil
}

class NotificationView: UIViewController {
    
    struct Metrics {
        static let width: CGFloat = 195
        static let visibleRight: CGFloat = -rightShift
        static let hiddenRight: CGFloat = -width
        static let rightShift: CGFloat = 12
    }
    
    private let textLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .Center
        label.textColor = UIColor.whiteColor()
        label.font = FontFamily.SFUIDisplay.Semibold.font(12)
        return label
    }()
    
    private let customView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(asset: .NotificationBackground)
        view.userInteractionEnabled = true
        return view
    }()
    
    private let statusContainerView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(asset: .NotificationStatusBackground)
        return view
    }()
    
    private let loadingView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        view.startAnimating()
        view.sizeToFit()
        view.transform = CGAffineTransformMakeScale(0.8, 0.8)
        return view
    }()
    
    private let successView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .ScaleAspectFit
        view.image = UIImage(asset: .NotificationSuccessIcon)
        return view
    }()
    
    private let errorView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = UIColor.redColor()
        return view
    }()
    
    private var dismissTimer: NSTimer?
    
    private var isObserving = false
    
    private(set) var notification: Notification!
    
    private var stateMachine: ViewStateMachine!
    
    required convenience init(notification: Notification) {
        self.init(nibName: nil, bundle: nil)
        
        stateMachine = ViewStateMachine(view: statusContainerView)
        stateMachine["Success"] = successView
        stateMachine["Loading"] = loadingView
        stateMachine["Error"] = errorView
        let inset: CGFloat = 4
        stateMachine.insets = UIEdgeInsetsMake(inset, inset, inset, inset)
        
        self.notification = notification
    }
    
    override func loadView() {
        view = customView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startObservingNotification()
        setup()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        cancelTimer()
    }
    
    func show() {
        NotificationManager.dismiss()
        
        stateMachine.transitionToState(.View(notification.status.description()), animated: false, completion: nil)
        
        let viewController = notification.viewController
        self.willMoveToParentViewController(viewController)
        viewController.addChildViewController(self)
        self.didMoveToParentViewController(viewController)
        viewController.view.addSubview(self.view)
        
        layout()
        
        customView <- Right(NotificationView.Metrics.hiddenRight)
        customView.setNeedsLayout()
        customView.layoutIfNeeded()
        
//        self.customView.transform = CGAffineTransformTranslate(self.customView.transform, -NotificationView.Metrics.hiddenRight, 0)
        
        animate(duration: 0.6) {
//            self.customView.transform = CGAffineTransformIdentity
            self.customView <- Right(NotificationView.Metrics.visibleRight)
            self.customView.setNeedsLayout()
            self.customView.layoutIfNeeded()
            }.withSpring(dampingRatio: 0.7, initialVelocity: 0)
        
        if let duration = notification.duration {
            startTimer(duration)
        }
    }
    
    func update(status: Notification.Status, message: String?) {
        stateMachine.transitionToState(.View(status.description()), animated: true, completion: nil)
    }
    
    func dismissAnimated(animationDuration: NSTimeInterval = 0.3) {
        
        cancelTimer()
        willMoveToParentViewController(nil)
        
        let completion = { (complete: Bool) -> Void in
            if complete {
                self.view.removeFromSuperview()
                self.removeFromParentViewController()
                self.didMoveToParentViewController(nil)
            }
        }
        
        animate(duration: animationDuration) {
            self.customView <- Right(NotificationView.Metrics.hiddenRight - 20)
            self.customView.setNeedsLayout()
            self.customView.layoutIfNeeded()
        }.withSpring(dampingRatio: 0.5, initialVelocity: 0)
        .withCompletion(completion)
    }
    
    func dismiss() {
        dismissAnimated()
    }
    
    func dismissQuickly() {
        dismissAnimated(0.1)
    }
    
    private func cancelTimer() {
        if let timer = dismissTimer {
            timer.invalidate()
            dismissTimer = nil
        }
    }
    
    private func startTimer(duration: NSTimeInterval) {
        dismissTimer = NSTimer.scheduledTimerWithTimeInterval(duration, target: self, selector: #selector(NotificationView.dismiss), userInfo: nil, repeats: false)
    }
    
    private func startObservingNotification() {
        if isObserving != true {
            isObserving = true
            let center = NSNotificationCenter.defaultCenter()
            center.addObserver(self, selector: nil, name: NotificationManager.Constants.DidChangeNotificationToSuccessStatus, object: nil)
            center.addObserver(self, selector: nil, name: NotificationManager.Constants.DidChangeNotificationToError, object: nil)
            center.addObserver(self, selector: #selector(NotificationView.dismiss), name: NotificationManager.Constants.ShouldHideNotification, object: nil)
            center.addObserver(self, selector: #selector(NotificationView.dismissQuickly), name: NotificationManager.Constants.ShouldHideQuicklyNotification, object: nil)
        }
    }
    
    private func stopObservingNotification() {
        if isObserving {
            let center = NSNotificationCenter.defaultCenter()
            center.removeObserver(self)
            isObserving = false
        }
    }
    
    private func setup() {
        view.addSubview(textLabel)
        view.addSubview(statusContainerView)
        
        textLabel.text = notification.message
    }
    
    private func layout() {
        textLabel <- [
            Left(10),
            Right(10 + Metrics.rightShift),
            Top(13)
        ]
        
        view <- [
            Width(NotificationView.Metrics.width),
            Height(26).like(textLabel),
            Right(),
            Top(70)
        ]
        
        statusContainerView <- [
            Top(-11),
            CenterX(),
            Size(22)
        ]
    }
    
    deinit {
        stopObservingNotification()
    }
    
}

class NotificationManager {
    
    static private var dismissTimer: NSTimer?
    
    struct Constants {
        static let DidChangeNotificationToSuccessStatus =  "NotificationManager.Constants.DidChangeNotificationToSuccessStatus"
        static let DidChangeNotificationToError =  "NotificationManager.Constants.DidChangeNotificationToError"
        static let ShouldHideNotification =  "NotificationManager.Constants.ShouldHideNotification"
        static let ShouldHideQuicklyNotification =  "NotificationManager.Constants.ShouldHideQuicklyNotification"
        static let Duration = 2
    }
    
    class func show(notication: Notification) {
        dismissQuickly()
        
        let notificationView = NotificationView(notification: notication)
        notificationView.show()
    }
    
    class func update(status: Notification.Status, message: String?) {
        var notificationName: String? = nil
        
        switch status {
        case .Success:
            notificationName = Constants.DidChangeNotificationToSuccessStatus
        case .Error:
            notificationName = Constants.DidChangeNotificationToError
        default:
            break
        }
        
        var userInfo: [String: String]? = nil
        
        if let message = message {
            userInfo = ["message": message]
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName(notificationName!, object: nil, userInfo: userInfo)
    }
    
    class func dismissDelayed() {
        dismiss(1)
    }
    
    @objc class func dismissImmediately() {
        dismiss(0)
    }
    
    class func dismiss(after: NSTimeInterval = 0) {
        if after > 0 {
            cancelTimer()
            dismissTimer = NSTimer.scheduledTimerWithTimeInterval(after, target: NotificationManager.self, selector: #selector(NotificationManager.dismissImmediately), userInfo: nil, repeats: false)
        } else {
            sendDismissNotification()
        }
    }
    
    class func cancelTimer() {
        if let timer = dismissTimer {
            timer.invalidate()
            dismissTimer = nil
        }
    }
    
    class func sendDismissNotification() {
        NSNotificationCenter.defaultCenter().postNotificationName(Constants.ShouldHideNotification, object: nil)
    }
    
    class func dismissQuickly() {
        NSNotificationCenter.defaultCenter().postNotificationName(Constants.ShouldHideQuicklyNotification, object: nil)
    }
    
}
