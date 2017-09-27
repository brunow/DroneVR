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

class ManualViewController: UIViewController, NotificationPresentable, Disposable, Dronable, VirtualJoystickMovable, ConnectionPresentable, MenuPresentable, Flyingable {
    
    internal var drone: PADroneViewModel {
        get {
            return self.flyingViewModel.drone
        }
    }
    
    private var gamePad: GamePadViewModel {
        get {
            return self.flyingViewModel.gamePad
        }
    }
    
    let disposeBag = DisposeBag()
    let customView = FlyingView()
    let flyingViewModel: ManualViewModel
    var showAllInformations = Variable(false)
    
    required init(drone: PADroneViewModel) {
        self.flyingViewModel = ManualViewModel(drone: drone)
        
        super.init(nibName: nil, bundle: nil)
        
        drone.connect().subscribeNext { _ in
            
        }.addDisposableTo(disposeBag)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("ddd")
    }
    
    override func loadView() {
        self.view = self.customView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.bindWithViewModel()
        self.bindActions()
        self.bindVirtualJoystick()
        self.bindCamera()
        self.makeMenuPresentable(self.customView.normalHud.moreBtn)
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return .Landscape
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func bindActions() {
        self.customView.normalHud.emergencyBtn.addTarget(self, action: #selector(ManualViewController.didPressEmergency), forControlEvents: .TouchUpInside)
        
        self.customView.normalHud.takeOffLandBtn.addTarget(self, action: #selector(ManualViewController.didPressTakeOffLand), forControlEvents: .TouchUpInside)
        
        self.customView.normalHud.takePhotoBtn.addTarget(self, action: #selector(ManualViewController.didPressTakePhoto), forControlEvents: .TouchUpInside)
        
        self.customView.normalHud.recordingBtn.addTarget(self, action: #selector(ManualViewController.didPressToggleVideo), forControlEvents: .TouchUpInside)
        
        let firstTapGlassGesture = UITapGestureRecognizer(target: self, action: #selector(ManualViewController.didPressVRView))
        let secondTapGlassGesture = UITapGestureRecognizer(target: self, action: #selector(ManualViewController.didPressVRView))
        customView.leftGlassesHud.addGestureRecognizer(firstTapGlassGesture)
        customView.rightGlassesHud.addGestureRecognizer(secondTapGlassGesture)
        
        self.customView.normalHud.metricsChangeView.distanceTypeBtn.rx_tap.flatMap{ [unowned self] in
            self.flyingViewModel.config.toggleDistanceType()
        }.subscribeNext {
            
        }.addDisposableTo(disposeBag)
        
        self.customView.normalHud.metricsChangeView.speedTypeBtn.rx_tap.flatMap{ [unowned self] in
            self.flyingViewModel.config.toggleSpeedType()
        }.subscribeNext {
            
        }.addDisposableTo(disposeBag)
        
        drone.isSendingSettings.asDriver().distinctUntilChanged().skip(2).driveNext{ [unowned self] sending in
            if sending {
                self.showLoadingNotification("Sending settings")
            } else {
                self.dismissNotification(true)
            }
        }.addDisposableTo(disposeBag)
        
        drone.goHome.asDriver().distinctUntilChanged().skip(1).driveNext{ [unowned self] home in
            if home {
                self.showLoadingNotification("Returning home")
            } else {
                self.dismissNotification(true)
            }
        }.addDisposableTo(disposeBag)

    }
    
    func bindVirtualJoystick() {
        let leftControll = self.customView.normalHud.leftControlView
        let rightControll = self.customView.normalHud.rightControlView
        self.makeVirtualJoysticlMovable(leftControlView: leftControll, rightControlView: rightControll)
    }
    
    func bindCamera() {
        if self.flyingViewModel.drone.hasCamera() {
            self.makeVideoPresentable()
            
        } else {
            self.customView.rightGlassesHud.videoView.hidden = true
            self.customView.leftGlassesHud.videoView.hidden = true
            self.customView.normalHud.videoView.hidden = true
        }
    }
    
    func bindWithViewModel() {
        self.makeFlyingInformationsPresentable()
        self.makeFlyingConfigPresentable(flyingViewModel.config)
        self.makeConnectionPresentable()
        
        self.flyingViewModel.gamePad.controllerStateDidChange.asDriver(onErrorJustReturn: false).driveNext { [unowned self] connected in
            self.customView.normalHud.takePhotoBtn.hidden = connected
            self.customView.normalHud.leftControlView.hidden = connected
            self.customView.normalHud.rightControlView.hidden = connected
            self.customView.normalHud.takeOffLandBtn.hidden = connected
//            self.customView.normalHud.metricsChangeView.hidden = connected
        }.addDisposableTo(disposeBag)
        
        self.flyingViewModel.vrMode.asDriver().driveNext { [unowned self] vrMode in
            self.customView.normalHud.hidden = vrMode
        }.addDisposableTo(disposeBag)
        
        drone.shouldExitFly.subscribeNext { [weak self] in
            guard let _self = self else { return }
            _self.dismissViewControllerAnimated(true, completion: nil)
            
        }.addDisposableTo(disposeBag)
    }

}

// MARK: Actions
extension ManualViewController {
    
    func didPressVRView() {
        showMenu()
    }
    
    func didPressTakeOffLand() {
        self.drone.toggleTakeOff().subscribeNext { _ in
            
        }.addDisposableTo(disposeBag)
    }
    
    func didPressEmergency() {
        self.drone.emergency().subscribeNext { _ in
            
        }.addDisposableTo(disposeBag)
    }
    
    func didPressTakePhoto() {
        self.drone.takePhoto().subscribeNext { _ in
            
        }.addDisposableTo(disposeBag)
    }
    
    func didPressToggleVideo() {
        self.drone.toggleRecording().subscribeNext { _ in
            
        }.addDisposableTo(disposeBag)
    }
    
}

// MARK: Private
extension ManualViewController {
    
    
    
}

// MARK: FlyingConfigPresentable
extension ManualViewController: FlyingConfigPresentable {
    func didChangeDistanceConfig(title: String) {
        self.customView.normalHud.metricsChangeView.distanceTypeBtn.setTitle(title, forState: .Normal)
//        self.customView.leftGlassesHud.distanceTypeLabel.text = title
//        self.customView.rightGlassesHud.distanceTypeLabel.text = title
    }
    
    func didChangeSpeedConfig(title: String) {
        self.customView.normalHud.metricsChangeView.speedTypeBtn.setTitle(title, forState: .Normal)
//        self.customView.leftGlassesHud.speedTypeLabel.text = title
//        self.customView.rightGlassesHud.speedTypeLabel.text = title
    }
}

// MARK: FlyingInformationsPresentable
extension ManualViewController: FlyingInformationsPresentable {
    func didUpdateBattery(level: Int, lowPower: Bool) {
        self.customView.normalHud.batteryView.setBatteryLevel(level)
        customView.leftGlassesHud.hud.batteryView.text = "\(level)%"
        customView.rightGlassesHud.hud.batteryView.text = "\(level)%"
        self.customView.normalHud.lineBatteryView.level = level
        
        customView.leftGlassesHud.hud.batteryView.textLabel.textColor = Application.colorForBattery(level, vrMode: true)
        customView.rightGlassesHud.hud.batteryView.textLabel.textColor = Application.colorForBattery(level, vrMode: true)
        customView.leftGlassesHud.hud.batteryView.imageView.tintColor = Application.colorForBattery(level, vrMode: true)
        customView.rightGlassesHud.hud.batteryView.imageView.tintColor = Application.colorForBattery(level, vrMode: true)
        customView.leftGlassesHud.hud.batteryView.imageView.image = Application.imageForBattery(level)
        customView.rightGlassesHud.hud.batteryView.imageView.image = Application.imageForBattery(level)
        
        let shouldHideGlassesBattery = !lowPower
        self.customView.normalHud.batteryView.hidden = shouldHideGlassesBattery
    }
    
    func didUpdateHorizontalSpeed(speed: String) {
        customView.leftGlassesHud.hud.speedView.text = speed
        customView.rightGlassesHud.hud.speedView.text = speed
        customView.normalHud.metricsView.speed = speed
    }
    
    func didUpdateAltitude(altitude: String) {
        customView.normalHud.metricsView.altitude = altitude
        customView.leftGlassesHud.hud.altitudeView.text = altitude
        customView.rightGlassesHud.hud.altitudeView.text = altitude
    }
    
    func didUpdateDistance(distance: String) {
        customView.normalHud.metricsView.distance = distance
        customView.leftGlassesHud.hud.distanceView.text = distance
        customView.rightGlassesHud.hud.distanceView.text = distance
    }
    
    func didUpdateGpsSafety(safe: Bool) {
        customView.normalHud.gpsLabel.hidden = safe
        customView.leftGlassesHud.gpsLabel.hidden = safe
        customView.rightGlassesHud.gpsLabel.hidden = safe
    }
    
    func didUpdateRecordingState(recording: Bool) {
        customView.normalHud.recordingBtn.setRecording(recording, animated: true)
        customView.leftGlassesHud.hud.recordingView.hidden = !recording
        customView.rightGlassesHud.hud.recordingView.hidden = !recording
        customView.rightGlassesHud.hud.stackView.setNeedsLayout()
        customView.rightGlassesHud.hud.stackView.layoutIfNeeded()
    }
    
    func didUpdateStayingState(flying: Bool) {
        let takeOffBtn = customView.normalHud.takeOffLandBtn
        let state: TakeOffButton.State = flying ? .Landing : .TakeOff
        takeOffBtn.setState(state, animated: true)
    }
}

// MARK: VideoPresentable
extension ManualViewController: VideoPresentable {
    func configureVideoDecoder(decoder: ARCONTROLLER_Stream_Codec_t) -> Bool {
        customView.rightGlassesHud.videoView.configureDecoder(decoder)
        customView.leftGlassesHud.videoView.configureDecoder(decoder)
        return customView.normalHud.videoView.configureDecoder(decoder)
    }
    
    func didReceiveVideoFrame(frame: UnsafeMutablePointer<ARCONTROLLER_Frame_t>) -> Bool {
        customView.rightGlassesHud.videoView.displayFrame(frame)
        customView.leftGlassesHud.videoView.displayFrame(frame)
        return customView.normalHud.videoView.displayFrame(frame)
    }
    
    func diReceiveVideoImage(image: UIImage) {
        customView.normalHud.backgroundImageView.image = image
        customView.leftGlassesHud.backgroundImageView.image = image
        customView.rightGlassesHud.backgroundImageView.image = image
    }
}


