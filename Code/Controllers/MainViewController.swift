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

class MainViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    let discoveringViewModel = DroneDiscoveringViewModel()
    let customView = MainView()
    
    convenience init() {
        self.init(nibName: nil, bundle: nil)
        self.title = nil
        
        Application.appearance()
    }
    
    override func loadView() {
        self.view = self.customView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        showFlyButton(false, animated: false)
        animateStateImage(true)
        showDroneName(false, animated: false)
        
        discoveringViewModel.found.asDriver()
            .distinctUntilChanged()
            .driveNext { [weak self] found in
                guard let _self = self else { return }
                let name = found ? _self.discoveringViewModel.name() : nil
                _self.showFlyButton(found, animated: true)
                _self.animateStateImage(!found)
                _self.showDroneName(found, animated: true, name: name)
                
        }.addDisposableTo(disposeBag)

        customView.flyBtn.addTarget(self, action: #selector(MainViewController.didPressFly), forControlEvents: .TouchUpInside)
        customView.findDroneBtn.addTarget(self, action: #selector(MainViewController.didPressFindMyDrone), forControlEvents: .TouchUpInside)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        customView.findDroneBtn.hidden = !RecoveryViewModel.hasLocation()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        discoveringViewModel.startDiscovering()
        
        animateBackground()
    }
    
    override func viewDidDisappear(animated: Bool) {
        discoveringViewModel.stopDiscovering()
        
        animateBackground(false)
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return .Landscape
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
}

// MARK: Actions
extension MainViewController {
    
    func didPressFly() {
        var vc: ManualViewController?
        
        if let drone = discoveringViewModel.drone() {
            vc = ManualViewController(drone: drone)
        }
        
        if let vc = vc {
            presentViewController(vc, animated: true, completion: nil)
        }
    }
    
    func didPressFindMyDrone() {
//        let vc = StoryboardScene.MainStoryboard.instantiateSettingsVC()
//        let vc = StoryboardScene.MainStoryboard.instantiateMapVC()
        let vc = MapViewController()
        presentViewController(vc, animated: true, completion: nil)
    }
    
}

// MARK: Private
extension MainViewController {
    
    private func animateBackground(animateBackground: Bool? = true) {
        self.customView.backgroundImageView.layer.removeAllAnimations()
        self.customView.backgroundImageView.transform = CGAffineTransformIdentity
        
        if animateBackground == true {
            animate(duration: 48) {
                self.customView.backgroundImageView.scale(sx: 1.8, sy: 1.8)
                }.withOption([.Autoreverse, .Repeat])
                .withDelay(0.2)
            
        }
    }
    
    private func animateStateImage(animated: Bool) {
    }
    
    private func showDroneName(show: Bool, animated: Bool, name: String? = nil) {
        let alpha: CGFloat = show ? 1 : 0
        customView.connectedStateImage.name = name
        
        if animated {
            animate(duration: 0.3) {
                self.customView.connectedStateImage.connectedImageView.alpha = alpha
                self.customView.connectedStateImage.nameLabel.alpha = alpha
                self.customView.connectedStateImage.connectingLabel.alpha = show ? 0 : 1
            }
            .withOption(.CurveEaseInOut)
            
        } else {
            self.customView.connectedStateImage.connectedImageView.alpha = alpha
            self.customView.connectedStateImage.nameLabel.alpha = alpha
            self.customView.connectedStateImage.connectingLabel.alpha = show ? 0 : 1
        }
    }
    
    private func showFlyButton(show: Bool, animated: Bool) {
        if animated {
            animate(duration: 0.3) {
                self.customView.flyBtn.alpha = show ? 1 : 0
            }
            .withOption(.CurveEaseIn)
            
        } else {
            customView.flyBtn.alpha = show ? 1 : 0
        }
    }
    
}



