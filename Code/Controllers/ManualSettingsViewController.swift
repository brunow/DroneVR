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

class ManualSettingsViewController: SettingsViewController {
    
    private(set) lazy var manualSettingsView = ManualSettingsView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setValues()
        bindWithViewModel()
    }
    
    func setValues() {
        let viewModel = ManualViewModel(drone: drone!)
        
        manualSettingsView.leftHanded.switchView.on = viewModel.config.leftHanded.value
        manualSettingsView.outdoor.switchView.on = viewModel.outdoor.value
        manualSettingsView.bankedMode.switchView.on = viewModel.bankedMode.value
        manualSettingsView.rollStabilisation.switchView.on = viewModel.rollStabilisation.value
        manualSettingsView.fpvMode.switchView.on = viewModel.config.fpvMode.value
//        manualSettingsView.liveFacebook.switchView.on = viewModel.liveFacebook.value
    }
    
    func bindWithViewModel() {
        let viewModel = ManualViewModel(drone: drone!)
        
//        manualSettingsView.bankedMode.switchView.rx_value.subscribeNext { [weak self] bankedMode in
//            guard let _self = self else { return }
//            _self.manualSettingsView.rollStabilisation.hidden = !bankedMode
//            
//        }.addDisposableTo(disposeBag)
        
        manualSettingsView.frameRate.selectedIndex.asDriver().driveNext {
            print($0)
        }.addDisposableTo(disposeBag)
        
        manualSettingsView.leftHanded.switchView.rx_value.bindTo(viewModel.config.leftHanded).addDisposableTo(disposeBag)
        manualSettingsView.outdoor.switchView.rx_value.bindTo(viewModel.outdoor).addDisposableTo(disposeBag)
        manualSettingsView.bankedMode.switchView.rx_value.bindTo(viewModel.bankedMode).addDisposableTo(disposeBag)
        manualSettingsView.rollStabilisation.switchView.rx_value.bindTo(viewModel.rollStabilisation).addDisposableTo(disposeBag)
        manualSettingsView.fpvMode.switchView.rx_value.bindTo(viewModel.config.fpvMode).addDisposableTo(disposeBag)
//        manualSettingsView.liveFacebook.switchView.rx_value.bindTo(viewModel.liveFacebook).addDisposableTo(disposeBag)
    }
}

// MARK: SettingsViewControllerable
extension ManualSettingsViewController {
    
    override func settingsView() -> UIView {
        return manualSettingsView
    }
    
    override func settingsFlightViewController() -> UIViewController {
        return ManualViewController(drone: drone!)
    }
    
}