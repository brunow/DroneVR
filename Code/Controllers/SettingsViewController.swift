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
import RxSwift
import RxCocoa
import EasyPeasy

protocol SettingsViewControllerable: class {
    
    func settingsView() -> UIView
    
    func settingsFlightViewController() -> UIViewController
    
}

class SettingsViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    var drone: PADroneViewModel?
    
    let customView = SettingsView()
    
    required init(drone: PADroneViewModel) {
        self.drone = drone
        
        super.init(nibName: nil, bundle: nil)
        title = nil
        
        transitioningDelegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func loadView() {
        view = customView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupContainer()
        
        customView.closeBtn.addTarget(self, action: #selector(SettingsViewController.closeAction), forControlEvents: .TouchUpInside)
        customView.actionBtn.addTarget(self, action: #selector(SettingsViewController.goAction), forControlEvents: .TouchUpInside)
    }
    
}

// MARK: Actions
extension SettingsViewController {
    
    func goAction() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func closeAction() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
}

// MARK: SettingsViewControllerable
extension SettingsViewController: SettingsViewControllerable {
    
    func settingsView() -> UIView {
        return UIView()
    }
    
    func settingsFlightViewController() -> UIViewController {
        return UIViewController()
    }
    
}


// MARK: Private
extension SettingsViewController {
    
    private func setupContainer() {
        let settings = settingsView()
        let scrollView = customView.scrollView
        scrollView.addSubview(settings)
        
        settings <- [
            Left(),
            Top(),
            Width(-10).like(scrollView, .Width)
        ]
        
        settings <- Bottom().to(scrollView, .Bottom)
        settings <- Right().to(scrollView, .Right)
    }
    
}

// MARK: UIViewControllerTransitioningDelegate
extension SettingsViewController: UIViewControllerTransitioningDelegate {
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        if presented.isKindOfClass(SettingsViewController) {
            return MenuVCTransitions(transitionType: .Present)
        }
        
        return nil
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if dismissed.isKindOfClass(SettingsViewController) {
            return MenuVCTransitions(transitionType: .Dismiss)
        }
        
        return nil
    }
    
}
