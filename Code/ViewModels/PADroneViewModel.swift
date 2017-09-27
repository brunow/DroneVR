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
import CoreLocation
import GCDKit

enum DroneConnectionState {
    case Connected
    case Disconnected
    case Paused
}

enum DroneFlyingState {
    case Landed
    case TakingOff
    case Hovering
    case Flying
    case Landing
    case Emergency
}

class PADroneViewModel: NSObject {
    private lazy var backgroundScheduler: ConcurrentDispatchQueueScheduler = {
        let queue = dispatch_queue_create("droneQueue", DISPATCH_QUEUE_CONCURRENT)
        return ConcurrentDispatchQueueScheduler(queue: queue)
    }()
    
    internal var currentSettings: DroneMetrics = DroneMetrics()
    var minSettings = DroneMetrics()
    var maxSettings = DroneMetrics()
    
    internal let cameraImage: BehaviorSubject<UIImage?> = BehaviorSubject(value: nil)
    
    // Others
    let driver: PADriverProtocol
    var battery: Variable<Int> = Variable(100)
    var recording: Variable<Bool> = Variable(false)
    var safeGPS: Variable<Bool> = Variable(false)
    var deviceLocation: Variable<CLLocation?> = Variable(nil)
    var droneLocation: Variable<CLLocation?> = Variable(nil)
    var goHome = Variable(false)
    var wifiOutdoor = Variable(false)
    var videoFrameRate = Variable<VideoFrameRate>(.FrameRate24)
    var stabilizationPitch = Variable(true)
    var stabilizationRoll = Variable(true)
    var returnHomeDelay = Variable(60)
    let mediaDownloadDidFinishSubject = PublishSubject<PaMediaModel>()
    let mediaDownloadDidProgressSubject = PublishSubject<(PaMediaModel, Float)>()
    let downloadedMedias = Variable<[PaMediaModel]>([])
    
    
    private var reconnectingSubscription: RxSwift.Disposable?
    
    // Speed
    var horizontalSpeed: Variable<Float> = Variable(0)
    var altitude: Variable<Double> = Variable(0)
    var distance: Variable<Double> = Variable(0)
    
    // State
    var didReceiveAllSettings: Variable<Bool> = Variable(false)
    var isSendingSettings: Variable<Bool> = Variable(false)
    var connecting: Variable<Bool> = Variable(false)
    var connected: Variable<Bool> = Variable(false)
    var connectionState: Variable<DroneConnectionState> = Variable(.Disconnected)
    var flyingState: Variable<DroneFlyingState> = Variable(.Landed)
    var flying: BehaviorSubject<Bool> = BehaviorSubject(value: false)
    var bankedTurn: Variable<Bool> = Variable(false)
    
    let shouldExitFly: PublishSubject<()> = PublishSubject()
    
    private let stateSem: dispatch_semaphore_t
    private let disposeBag = DisposeBag()
    
    private(set) lazy var locationManager:CLLocationManager = {
        let locationManager = CLLocationManager()
//        locationManager.distanceFilter = 4
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        return locationManager
    }()
    
    var configureDecoderBlock: ((ARCONTROLLER_Stream_Codec_t) -> Bool)?
    var didReceiveFrameBlock: ((UnsafeMutablePointer<ARCONTROLLER_Frame_t>) -> Bool)?

    required init(driver: PADriverProtocol) {
        self.stateSem = dispatch_semaphore_create(0);
        self.driver = driver
        
        super.init()
        
        connectionState.asObservable()
            .distinctUntilChanged()
            .filter { $0 == .Connected }
            .take(1).subscribeNext { [weak self] _ in
                guard let _self = self else { return }
                _self.setupReconnectingObserver()
                
        }.addDisposableTo(disposeBag)
        
        flyingState.asObservable().map { state in
            switch state {
            case .TakingOff, .Hovering, .Flying:
                return true
            default:
                return false
            }
        }
            .bindTo(flying)
            .addDisposableTo(disposeBag)
        
        self.connectionState.asObservable()
            .map{ $0 != .Disconnected }
            .subscribeNext { [unowned self] connected in
            self.connected.value = connected
            
            if connected {
                self.connecting.value = false
            } else {
                self.connecting.value = true
            }
            
        }.addDisposableTo(disposeBag)
        
//        setupReconnectingObserver()
        
        
        
//        let connectionStateObservable = self.connectionState.asObservable().map{ $0 != .Disconnected }
//        connectionStateObservable
        
//        connectionStateObservable.subscribeNext { [unowned self] connected in
//            if self.connected.value == true && connected == false {
//                self.tryReconnecting()
//                self.connecting.value = true
//            }
//            
//            self.connected.value = connected
//            
//            if connected {
//                self.connecting.value = false
//            }
//            
//        }.addDisposableTo(disposeBag)
        
//        NSTimer.schedule(repeatInterval: 1.0) { timer in
//            timer.invalidate()
//        }
//
//        let subscription = Observable<Int>.interval(0.3, scheduler: scheduler)
//            .observeOn(serialScheduler)
//            .subscribe { event in
//                print(event)
//        }
        
//        connectionStateObservable
//            .subscribe(onNext: { [unowned self] connected in
//                self.connected.value = connected
//                
//                if connected {
//                    self.connecting.value = false
//                } else {
//                    self.connect().subscribeNext {
//                        
//                    }.addDisposableTo(self.disposeBag)
//                }
//                
//            }, onDisposed: { [unowned self] in
//                if self.connectionState.value == .Connected {
//                    self.disconnectImmediatly()
//                }
//                
//            }).addDisposableTo(disposeBag)
        
        setupDriver()
    }
    
    deinit {
        disconnectImmediatly()
    }
    
    func hasReceivedAllSettings() -> Bool {
        return self.minSettings.hasAllSettings()
    }
    
    func hasSendAllSettings() -> Bool {
        return self.currentSettings.hasAllSettings()
    }
    
    func isDroneSimulator() -> Bool {
        return self.driver is PADummyDriver
    }
    
    func cameraImageObserver() -> Observable<UIImage> {
        return cameraImage.filterNil()
    }
    
    func emergency() -> Observable<Void> {
        return Observable.create { observer in
            self.driver.emergency()
            
            observer.onNext()
            observer.onCompleted()
            
            return NopDisposable.instance
        }.subscribeOn(backgroundScheduler)
    }
    
    func landing() -> Observable<Void> {
        return Observable.create { observer in
            self.driver.land()
            
            observer.onNext()
            observer.onCompleted()
            
            return NopDisposable.instance
        }.subscribeOn(backgroundScheduler)
    }
    
    func takeOff() -> Observable<Void> {
        return Observable.create { observer in
            self.driver.takeOff()
            
            observer.onNext()
            observer.onCompleted()
            
            return NopDisposable.instance
        }.subscribeOn(backgroundScheduler)
    }
    
    func connect() -> Observable<Void> {
        return Observable.create { [unowned self] observer in
            self.connectImmediately()
            
            observer.onNext()
            observer.onCompleted()
            
            return NopDisposable.instance
        }.subscribeOn(backgroundScheduler)
    }
    
    func disconnect() -> Observable<Void> {
        return Observable.create { observer in
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                self.disconnectImmediatly()
                observer.onNext()
                observer.onCompleted()
            })
            
            return NopDisposable.instance
        }
    }
    
    func connectImmediately() {
        connecting.value = true
        driver.connect()
        
        GCDQueue.Main.async {
            self.startLocationManager()
        }
    }
    
    func disconnectImmediatly() {
        reconnectingSubscription?.dispose()
        stopLocationManager()
        driver.disconnect()
//        dispatch_semaphore_wait(self.stateSem, DISPATCH_TIME_FOREVER)
    }
    
    func setupReconnectingObserver() {
        let subscription = Observable<Int>.interval(1, scheduler: backgroundScheduler)
            .observeOn(backgroundScheduler)
            .subscribe { [weak self] event in
                guard let _self = self else { return }
                
                if _self.connected.value == false {
//                    _self.connectImmediately()
                    _self.connecting.value = true
                    _self.disconnectImmediatly()
                    _self.shouldExitFly.onNext()
                }
        }
        
        reconnectingSubscription = subscription
        
//        let connectionStateObservable = connectionState.asObservable()
//            .skip(1)
//            .filter { $0 != .Disconnected }
//            .flatMap { [weak self] _ -> Observable<()> in
//                guard let _self = self else { return Observable.just() }
//                return _self.tryConnectUntilConnected()
//            }
//        
//        reconnectingSubscription = connectionStateObservable
//            .subscribeNext {
//        }
        
    }
    
    func takePhoto() -> Observable<Void> {
        return Observable.create { [unowned self] observer in
            self.driver.takePicture()
            
            observer.onNext()
            observer.onCompleted()
            
            return NopDisposable.instance
        }.subscribeOn(backgroundScheduler)
    }
    
    func toggleRecording() -> Observable<Void> {
        return self.startRecordingMovie(!self.recording.value)
    }
    
    func startRecordingMovie(start: Bool) -> Observable<Void> {
        return Observable.create { [unowned self] observer in
            self.recording.value = start
            self.driver.startRecordingMovie(start)
            
            observer.onNext()
            observer.onCompleted()
            
            return NopDisposable.instance
        }.subscribeOn(backgroundScheduler)
    }
    
    func toggleTakeOff() -> Observable<Void> {
        if flyingState.value == .Flying || flyingState.value == .Hovering {
            return landing()
            
        } else if flyingState.value == .Landed || flyingState.value == .Emergency {
            return takeOff()
        }
        
        return Observable.just()
    }
    
    func setBankedTurn(enable: Bool) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let _self = self else { return NopDisposable.instance }
            
            _self.driver.sendPilotingBankedTurn(enable)
            
            observer.onNext()
            observer.onCompleted()
            
            return NopDisposable.instance
            }.subscribeOn(backgroundScheduler)
    }
    
    func setCameraOrientation(tilt: Int, pan: Int) -> Observable<Void> {
        //        print("titl \(tilt) pan \(pan)")
        return Observable.create { [unowned self] observer in
            
            let min = -128
            let max = 128
            
            if tilt <= max && tilt >= min && pan <= max && pan >= min {
                self.driver.setCameraOrientation(Int(tilt), pan: Int(pan))
            }
            
            observer.onNext()
            observer.onCompleted()
            
            return NopDisposable.instance
        }.subscribeOn(backgroundScheduler)
    }
    
    func centerCameraOrientation() -> Observable<Void> {
        return self.setCameraOrientation(0, pan: 0)
            .subscribeOn(backgroundScheduler)
    }
    
    func pitch(value: Float) -> Observable<Void> {
        if self.isSendingSettings.value {
            return Observable.just()
        }
        
        return Observable.create { observer in
            let value = Int(value*100)
            self.driver.setPitch(value)
            
            observer.onNext()
            observer.onCompleted()
            
            return NopDisposable.instance
        }.subscribeOn(backgroundScheduler)
    }
    
    func roll(value: Float) -> Observable<Void> {
        if self.isSendingSettings.value {
            return Observable.just()
        }
        
        return Observable.create { observer in
            let value = Int(value*100)
            self.driver.setRoll(value)
            
            observer.onNext()
            observer.onCompleted()
            
            return NopDisposable.instance
        }.subscribeOn(backgroundScheduler)
    }
    
    func yaw(value: Float) -> Observable<Void> {
        if self.isSendingSettings.value {
            return Observable.just()
        }
        
        return Observable.create { observer in
            let value = Int(value*100)
            self.driver.setYaw(value)
            
            observer.onNext()
            observer.onCompleted()
            
            return NopDisposable.instance
        }.subscribeOn(backgroundScheduler)
    }
    
    func gaz(value: Float) -> Observable<Void> {
        if self.isSendingSettings.value {
            return Observable.just()
        }
        
        return Observable.create { observer in
            let value = Int(value*100)
            self.driver.setGaz(value)
            
            observer.onNext()
            observer.onCompleted()
            
            return NopDisposable.instance
        }.subscribeOn(backgroundScheduler)
    }
    
    func stopMoving() -> Observable<Void> {
        return Observable.create { observer in
            self.driver.setGaz(0)
            self.driver.setPitch(0)
            self.driver.setRoll(0)
            self.driver.setYaw(0)
            
            observer.onNext()
            observer.onCompleted()
            
            return NopDisposable.instance
            }.subscribeOn(backgroundScheduler)
    }
    
    func settingsNoFlyOverMaxDistance(noFly: Bool) -> Observable<Void> {
        return Observable.create { [unowned self] observer in
            self.driver.settingsNoFlyOverMaxDistance(noFly)
            
            observer.onNext()
            observer.onCompleted()
            
            return NopDisposable.instance
        }.subscribeOn(backgroundScheduler)
    }
    
    func settingsPilotingMaxDistance(maxDistance: Float) -> Observable<Void>{
        return Observable.create { [unowned self] observer in
            self.driver.settingsPilotingMaxDistance(maxDistance)
            
            observer.onNext()
            observer.onCompleted()
            
            return NopDisposable.instance
        }.subscribeOn(backgroundScheduler)
    }
    
    func settingsPilotingMaxAltitude(maxAltitude: Float) -> Observable<Void>{
        return Observable.create { [unowned self] observer in
            self.driver.settingsPilotingMaxAltitude(maxAltitude)
            
            observer.onNext()
            observer.onCompleted()
            
            return NopDisposable.instance
        }.subscribeOn(backgroundScheduler)
    }
    
    func sendSettings(settings: DroneMetrics, returnHomeDelay: Int) -> Observable<Void> {
        if self.isSendingSettings.value {
            return Observable.just()
        }
        
        let drone = self
        
        let resetCurrentSettings: Observable<Void> = Observable.create { [unowned self] observer in
            self.currentSettings = DroneMetrics()
            self.isSendingSettings.value = true
            
            observer.onNext()
            observer.onCompleted()
            
            return NopDisposable.instance
        }
        
        return resetCurrentSettings
            .flatMap { drone.stopMoving() }
            .flatMap { drone.settingsPilotingMaxTilt(settings.maxTilt!) }
            .flatMap { drone.settingsNoFlyOverMaxDistance(true) }
            .flatMap { drone.settingsPilotingMaxDistance(settings.maxDistance!) }
            .flatMap { drone.settingsPilotingMaxAltitude(settings.maxAltitude!) }
            .flatMap { drone.settingsPilotingMaxVerticalSpeed(settings.verticalSpeed!) }
            .flatMap { drone.settingsPilotingMaxRotationSpeed(settings.rotationSpeed!) }
            .flatMap { drone.settingsPilotingOutdoor(true) }
            .flatMap { drone.settingsReturnHomeDelay(returnHomeDelay) }
    }
    
    func pilotingGoHome(start: Bool) -> Observable<Void> {
        return Observable.create { [unowned self] observer in
            self.driver.pilotingGoHome(start)
            
            observer.onNext()
            observer.onCompleted()
            
            return NopDisposable.instance
        }.subscribeOn(backgroundScheduler)
    }
    
    func pilotingFlatTrim() -> Observable<Void> {
        return Observable.create { [unowned self] observer in
            self.driver.pilotingFlatTrim()
            
            observer.onNext()
            observer.onCompleted()
            
            return NopDisposable.instance
        }.subscribeOn(backgroundScheduler)
    }
    
    func settingsPilotingMaxTilt(tilt: Float) -> Observable<Void> {
        return Observable.create { [unowned self] observer in
            self.driver.settingsPilotingMaxTilt(tilt)
            
            observer.onNext()
            observer.onCompleted()
            
            return NopDisposable.instance
        }.subscribeOn(backgroundScheduler)
    }
    
    func settingsPilotingMaxVerticalSpeed(speed: Float) -> Observable<Void> {
        return Observable.create { [unowned self] observer in
            self.driver.settingsPilotingMaxVerticalSpeed(speed)
            
            observer.onNext()
            observer.onCompleted()
            
            return NopDisposable.instance
        }.subscribeOn(backgroundScheduler)
    }
    
    func settingsPilotingMaxRotationSpeed(rotation: Float) -> Observable<Void> {
        return Observable.create { [unowned self] observer in
            self.driver.settingsPilotingMaxRotationSpeed(rotation)
            
            observer.onNext()
            observer.onCompleted()
            
            return NopDisposable.instance
        }.subscribeOn(backgroundScheduler)
    }
    
    func settingsPilotingOutdoor(outdoor: Bool) -> Observable<Void> {
        return Observable.create { [unowned self] observer in
            self.driver.settingsPilotingOutdoor(outdoor)
            
            observer.onNext()
            observer.onCompleted()
            
            return NopDisposable.instance
        }.subscribeOn(backgroundScheduler)
    }
    
    func settingsReturnHomeDelay(delay: Int) -> Observable<Void> {
        return Observable.create { [unowned self] observer in
            self.driver.settingsReturnHomeDelay(UInt(delay))
            
            observer.onNext()
            observer.onCompleted()
            
            return NopDisposable.instance
        }.subscribeOn(backgroundScheduler)
    }
    
    func hasCamera() -> Bool {
        return self.driver.hasCamera()
    }
    
    func isConnected() -> Bool {
        return connected.value == true
    }
    
    func settingsPilotingBankedTurn(bankedTurn: Bool) -> Observable<Void> {
        return Observable.create { [unowned self] observer in
            self.driver.sendPilotingBankedTurn(bankedTurn)
            
            observer.onNext()
            observer.onCompleted()
            
            return NopDisposable.instance
        }.subscribeOn(backgroundScheduler)
    }
    
    func settingsVideoRecordingMode(bestQuality: Bool) -> Observable<Void> {
        return Observable.create { [unowned self] observer in
            self.driver.settingsVideoRecordingMode(bestQuality)
            
            observer.onNext()
            observer.onCompleted()
            
            return NopDisposable.instance
        }.subscribeOn(backgroundScheduler)
    }
    
    func settingsVideoStabilization(pitch: Bool, roll: Bool) -> Observable<Void> {
        return Observable.create { [weak driver] observer in
            driver?.settingsVideoStabilizationMode(roll, pitch: pitch)
            
            observer.onNext()
            observer.onCompleted()
            
            return NopDisposable.instance
        }.subscribeOn(backgroundScheduler)
    }
    
    func settingsVideoRecordingResolution(resolution: VideoResolution) -> Observable<Void> {
        return Observable.create { [weak driver] observer in
            driver?.settingsVideoRecordingResolution(resolution.toParrot())
            
            observer.onNext()
            observer.onCompleted()
            
            return NopDisposable.instance
            }.subscribeOn(backgroundScheduler)
    }
    
    func settingsVideoFrameRate(frameRate: VideoFrameRate) -> Observable<Void> {
        return Observable.create { [weak driver] observer in
            driver?.settingsVideoFrameRate(frameRate.toParrot())
            
            observer.onNext()
            observer.onCompleted()
            
            return NopDisposable.instance
            }.subscribeOn(backgroundScheduler)
    }
    
    func settingsVideoStreamMode(streamMode: StreamMode) -> Observable<Void> {
        return Observable.create { [weak driver] observer in
            driver?.sendVideoStreamMode(streamMode.toParrot())
            
            observer.onNext()
            observer.onCompleted()
            
            return NopDisposable.instance
            }.subscribeOn(backgroundScheduler)
    }
    
}

// MARK: Private
extension PADroneViewModel {
    
    private func tryConnectUntilConnected() -> Observable<()> {
        return Observable.create { [weak self] observer in
            guard let _self = self else { return NopDisposable.instance }
            
            let subscription = Observable<Int>
                .interval(0.5, scheduler: _self.backgroundScheduler)
                .flatMap { _ in _self.connect() }
                .subscribeNext {_ in
                
            }
            
            return subscription
        }
    }
    
    private func setFlat(flag: Int) {
        self.driver.setFlag(UInt(flag))
    }
    
}
//
