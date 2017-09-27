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
import RxSwift
import EasyPeasy

protocol MenuPresentable: class {
    
    func makeMenuPresentable(menuButton: UIButton)
    
    func showMenu()
    
    func menuPrimaryActions() -> [MenuViewController.Button]
    
    func menuSecondaryActions() -> [MenuViewController.Button]
    
}

extension MenuPresentable where Self:UIViewController, Self:Disposable, Self:Dronable, Self:Flyingable {
    
    func makeMenuPresentable(menuButton: UIButton) {
        menuButton.rx_tap.subscribeNext { [unowned self] in
            self.showMenu()
        }.addDisposableTo(disposeBag)
    }
    
    func showMenu() {
        let vc = MenuViewController(viewModel: flyingViewModel,
                                    primaryActions: menuPrimaryActions(),
                                    secondaryActions: menuSecondaryActions())
        
        vc.setBlurringView(self.view)
        self.presentViewController(vc, animated: true, completion: nil)
    }
    
    func menuPrimaryActions() -> [MenuViewController.Button] {
        return [.FindDrone, .VRMode, .ReturnHome]
    }
    
    func menuSecondaryActions() -> [MenuViewController.Button] {
        return [.FlatTrim, .Settings, .ExitFly]
    }
}
