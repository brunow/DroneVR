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
import AudioToolbox

class ManualViewModel: NSObject, FlyingGamepadAble, FlyingConfigable, Dronable, Disposable {
    private lazy var backgroundScheduler: ConcurrentDispatchQueueScheduler = {
        let queue = dispatch_queue_create("flyingBackgroundQueue", DISPATCH_QUEUE_CONCURRENT)
        return ConcurrentDispatchQueueScheduler(queue: queue)
    }()
    
    internal let disposeBag = DisposeBag()
    
    let virtualReality = VirtualRealityViewModel()
    let config = DroneConfigViewModel()
    
    let gamePad: GamePadViewModel = GamePadViewModel.sharedInstance
    var drone: PADroneViewModel
    let vrMode: Variable<Bool> = Variable(false)
    let recovery = RecoveryViewModel()
    let vrModeAvailable = BehaviorSubject(value: false)
    
    // Config
//    let leftHanded = Variable(false)
    let outdoor = Variable(true)
    let bankedMode = Variable(true)
//    let liveFacebook = Variable(false)
    let rollStabilisation = Variable(false)
//    let fpvMode = Variable(false)
    let frameRate: Variable<PADroneViewModel.VideoFrameRate> = Variable(.FrameRate24)
    
    required init(drone: PADroneViewModel) {
        self.drone = drone
        super.init()
        
        makeConfigable(config)
        bindVR()
        bindDroneConfigChange()
        makeGamepadable(gamePad, config: config, vr: virtualReality)
        recovery.saveLocationChange(drone.droneLocation.asObservable())
        bindBatteryAlertLevel()
        
        drone.connected.asObservable()
            .filter { $0 == true }
            .flatMap { [weak self] _ -> Observable<()> in
                guard let _self = self else { return .just() }
                return _self.sendSettings()
            }
            .subscribeNext {
            
        }.addDisposableTo(disposeBag)
    }
    
    deinit {
        self.virtualReality.stop()
    }
    
    private func bindBatteryAlertLevel() {
        Observable<Int>.interval(60, scheduler: backgroundScheduler)
            .map { [weak self] _ -> Int in
                guard let _self = self else { return 0 }
                return _self.drone.battery.value
            }
            .filter { $0 <= 20 }
            .subscribeNext { [weak self] _ in
                guard let _self = self else { return }
                if _self.drone.battery.value <= 20 {
                    AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                }
                
            }.addDisposableTo(disposeBag)
    }
    
    func sendSettings() -> Observable<Void> {
        let drone = self.drone
        let fpv = true
        let bankedMode = true //self.bankedMode.value
        let roll = false // rollStabilisation.value
        let bestVideoQuality = false// !config.fpvMode.value
        let rate = frameRate.value
        let streamMode: PADroneViewModel.StreamMode = fpv ? .LowLatency : .HighReliability
        let videoResolution: PADroneViewModel.VideoResolution = fpv ? .BestStreaming : .BestRecording
        let landed = drone.flyingState.value == .Landed
        let shouldUpdateResolution = landed
        
        return Observable.just()
            .flatMap { drone.settingsVideoStabilization(true, roll: roll) }
            .flatMap { drone.settingsVideoFrameRate(rate) }
            .flatMap { drone.settingsVideoStreamMode(streamMode) }
            .flatMap { drone.settingsVideoRecordingMode(bestVideoQuality) }
            .flatMap { shouldUpdateResolution ? drone.settingsVideoRecordingResolution(videoResolution) : Observable.just() }
            .flatMap { drone.settingsPilotingBankedTurn(bankedMode) }
    }
    
    private func bindDroneConfigChange() {
        drone.wifiOutdoor.asObservable().bindTo(outdoor).addDisposableTo(disposeBag)
        drone.bankedTurn.asObservable().bindTo(bankedMode).addDisposableTo(disposeBag)
        drone.stabilizationRoll.asObservable().bindTo(rollStabilisation).addDisposableTo(disposeBag)
        drone.videoFrameRate.asObservable().bindTo(frameRate).addDisposableTo(disposeBag)
    }
    
    private func bindVR() {
        gamePad.controllerStateDidChange.bindTo(vrModeAvailable).addDisposableTo(disposeBag)
        gamePad.controllerStateDidChange.filter({ $0 == false }).bindTo(vrMode).addDisposableTo(disposeBag)
        
        #if Simulator
            vrModeAvailable.onNext(true)
        #endif
        
        drone.startRecordingMovie(true).subscribeNext {
        }.addDisposableTo(disposeBag)
        
        virtualReality.didUpdateMotion.flatMap { [weak self] (roll, yaw) -> Observable<Void> in
            guard let _self = self else { return Observable.just() }
            
            return _self.drone.setCameraOrientation(Int(roll), pan: Int(yaw)) }
    
            .subscribeNext { _ in
                
        }.addDisposableTo(disposeBag)
    }
    
}
