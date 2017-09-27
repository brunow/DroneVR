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
import RxSwift
import RxCocoa

class MenuViewController: UIViewController {
    
    enum Button {
        case FindDrone, Settings, ExitFly, VRMode, ReturnHome, FlatTrim
        case Custom(button: UIControl)
    }
    
    let disposeBag = DisposeBag()
    
    let customView = MenuView()
    
    var drone: PADroneViewModel
    
    var flyingViewModel: ManualViewModel
    
    private lazy var returnHomeBtn: MenuIconButton = {
        let btn = MenuIconButton.button(.ReturnHome)
        return btn
    }()
    
    private lazy var vrModeBtn: MenuIconButton = {
        let btn = MenuIconButton.button(.VR)
        return btn
    }()
    
    private lazy var findDroneBtn: MenuIconButton = {
        let btn = MenuIconButton.button(.FindDrone)
        return btn
    }()
    
    private lazy var settingsBtn: MenuSimpleButton = {
        let btn = MenuSimpleButton(title: "Settings")
        return btn
    }()
    
    private lazy var exitFlyBtn: MenuSimpleButton = {
        let btn = MenuSimpleButton(title: "Exit fly mode")
        return btn
    }()
    
    private lazy var flatTrimBtn: MenuSimpleButton = {
        let btn = MenuSimpleButton(title: "Flat trim")
        return btn
    }()
    
    private var primaryActions: [Button]!
    
    private var secondaryActions: [Button]!
    
    required init(viewModel: ManualViewModel, primaryActions: [Button], secondaryActions: [Button]) {
        self.drone = viewModel.drone
        self.flyingViewModel = viewModel
        self.primaryActions = primaryActions
        self.secondaryActions = secondaryActions
        
        super.init(nibName: nil, bundle: nil)
        title = nil
        
        transitioningDelegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = customView
    }
    
    func setBlurringView(view: UIView) {
//        customView.blurView.underlyingView = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupButtons(primaryActions, primary: true)
        setupButtons(secondaryActions, primary: false)
        
        bindViewModel()
        bindActions()
    }
    
    func close() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func bindViewModel() {
        let scheduler = ConcurrentDispatchQueueScheduler(globalConcurrentQueueQOS: .Background)
        
        let vrSwitch = vrModeBtn.switchView
        
        // Vr mode
        flyingViewModel.vrModeAvailable.bindTo(vrSwitch.rx_enabled).addDisposableTo(disposeBag)
        flyingViewModel.vrMode.asObservable().observeOn(MainScheduler.instance).bindTo(vrSwitch.rx_value).addDisposableTo(disposeBag)
        vrSwitch.rx_value.skip(1).bindTo(flyingViewModel.vrMode).addDisposableTo(disposeBag)
        
        // Go home
        let homeObservable = drone.goHome.asObservable().throttle(0.05, scheduler: scheduler)
        homeObservable.observeOn(MainScheduler.instance).bindTo(returnHomeBtn.switchView.rx_value).addDisposableTo(disposeBag)
    }
    
    func bindActions() {
        customView.closeBtn.addTarget(self, action: #selector(MenuViewController.close), forControlEvents: .TouchUpInside)
        returnHomeBtn.switchView.addTarget(self, action: #selector(MenuViewController.didPressReturnHome), forControlEvents: .ValueChanged)
        customView.emergencyBtn.addTarget(self, action: #selector(MenuViewController.didPressEmergency), forControlEvents: .TouchUpInside)
        findDroneBtn.addTarget(self, action: #selector(MenuViewController.didPressMap), forControlEvents: .TouchUpInside)
        exitFlyBtn.addTarget(self, action: #selector(MenuViewController.didPressStopFlying), forControlEvents: .TouchUpInside)
        settingsBtn.addTarget(self, action: #selector(MenuViewController.didPressSettings), forControlEvents: .TouchUpInside)
        flatTrimBtn.addTarget(self, action: #selector(MenuViewController.didPressFlatTrim), forControlEvents: .TouchUpInside)
    }
    
}

// MARK: Actions
extension MenuViewController {
    
    func didPressFlatTrim() {
        drone.pilotingFlatTrim().subscribeNext {
            
        }.addDisposableTo(disposeBag)
    }
    
    func didPressReturnHome() {
        let goHome = drone.goHome.value
        
        drone.pilotingGoHome(!goHome).subscribeNext {
            
        }.addDisposableTo(disposeBag)
    }
    
    func didPressSettings() {
        let vc = SettingsViewController(drone: drone)
        presentViewController(vc, animated: true, completion: nil)
    }
    
    func didPressStopFlying() {
        drone.disconnectImmediatly()
        
        let vc = MainViewController()
        
        presentViewController(vc, animated: true, completion: {
            if let app = UIApplication.sharedApplication().delegate as? AppDelegate, let window = app.window {
                window.rootViewController = vc
            }
        })
    }
    
    func didPressMap() {
        let vc = MapViewController()
        presentViewController(vc, animated: true, completion: nil)
    }
    
    func didPressEmergency() {
        self.drone.emergency().subscribeNext { _ in
            
        }.addDisposableTo(disposeBag)
    }
    
}

// MARK: Private
extension MenuViewController {
    
    private func buttonForType(type: Button) -> UIControl {
        switch type {
        case .FindDrone:
            return findDroneBtn
        case .Settings:
            return settingsBtn
        case .ExitFly:
            return exitFlyBtn
        case .VRMode:
            return vrModeBtn
        case .ReturnHome:
            return returnHomeBtn
        case .FlatTrim:
            return flatTrimBtn
        case .Custom(let button):
            return button
        }
    }
    
    private func setupButtons(buttons: [Button], primary isPrimary: Bool) {
        let stackView = isPrimary ? customView.menuStackView : customView.simpleMenuStackView
        
        for type in buttons {
            let button = buttonForType(type)
            stackView.addArrangedSubview(button)
        }
    }
    
}

// MARK: UIViewControllerTransitioningDelegate
extension MenuViewController: UIViewControllerTransitioningDelegate {
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        if presented.isKindOfClass(MenuViewController) {
            return MenuVCTransitions(transitionType: .Present)
        }
        
        return nil
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if dismissed.isKindOfClass(MenuViewController) {
            return MenuVCTransitions(transitionType: .Dismiss)
        }
        
        return nil
    }
    
}

