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
import CoreLocation
import RxSwift

// MARK: PADriverDelegate
extension PADroneViewModel: PADriverDelegate {
    
    func setupDriver() {
        self.driver.delegate = self
    }
    
    func paDriver(paDriver: PADriverProtocol!, batteryDidChange batteryPercentage: Int32) {
        self.battery.value = Int(batteryPercentage)
    }
    
    func paDriver(paDriver: PADriverProtocol!, connectionDidChange state: PADriverDeviceState) {
        
        switch state {
        case PADriverDeviceStateRunning:
            self.connectionState.value = .Connected
            break
        case PADriverDeviceStateStopped:
            self.connectionState.value = .Disconnected
            break
        default:
            break
        }
        
    }
    
    func paDriver(paDriver: PADriverProtocol!, flyingStateDidChange state: PADriverFlyingState) {
        
        switch state {
        case PADriverFlyingStateLanded:
            self.flyingState.value = .Landed
            break
        case PADriverFlyingStateFlying:
            self.flyingState.value = .Flying
            break
        case PADriverFlyingStateHovering:
            self.flyingState.value = .Hovering
            break
        case PADriverFlyingStateTakingOff:
            self.flyingState.value = .TakingOff
            break
        case PADriverFlyingStateEmergency:
            self.flyingState.value = .Emergency
            break
        default:
            break
        }
    }
    
    func paDriver(paDriver: PADriverProtocol!, configureDecoder codec: ARCONTROLLER_Stream_Codec_t) -> Bool {
        return self.configureDecoderBlock!(codec)
    }
    
    func paDriver(paDriver: PADriverProtocol!, didReceiveFrame frame: UnsafeMutablePointer<ARCONTROLLER_Frame_t>) -> Bool {
        return self.didReceiveFrameBlock!(frame)
    }
    
    func paDriver(driver: PADriverProtocol!, didReceiveImage image: UIImage!) {
        cameraImage.onNext(image)
    }
    
    func paDriver(paDriver: PADriverProtocol!, didFoundMatchingMedias nbMedias: UInt) {
        
    }
    
    func paDriver(paDriver: PADriverProtocol!, media: PaMediaModel!, downloadDidProgress progress: Int32) {
        mediaDownloadDidProgressSubject.onNext((media, Float(progress)))
    }
    
    func paDriver(paDriver: PADriverProtocol!, mediaDownloadDidFinish media: PaMediaModel!) {
        mediaDownloadDidFinishSubject.onNext(media)
    }
    
    func paDriver(driver: PADriverProtocol!, altitudeDidChange altitude: Double) {
        self.altitude.value = altitude
    }
    
    func paDriver(driver: PADriverProtocol!, gpsSattelitesNumberDidChange satteliesNumber: UInt) {
    }
    
    func paDriver(driver: PADriverProtocol!, cameraCenterOrientationTilt tilt: Float, pan: Float) {
        self.currentSettings.cameraTilt = tilt
        self.currentSettings.cameraPan = pan
    }
    
    func paDriver(driver: PADriverProtocol!, speedDidChangeWithSpeedX speedX: Float, speedY: Float, speedZ: Float) {
        horizontalSpeed.value = sqrt(pow(speedX, 2) + pow(speedY, 2))
        //        √(speedX² + speedY²)
    }
    
    func paDriver(driver: PADriverProtocol!, positionDidChangeWithLatitude latitude: Double, longitude: Double, altitude: Double) {
//        self.altitude.value = altitude
        droneLocation.value = CLLocation(latitude: latitude, longitude: longitude)
        
        if let deviceLocation = deviceLocation.value {
            let droneLocation = CLLocation(latitude: latitude, longitude: longitude)
            self.distance.value = deviceLocation.distanceFromLocation(droneLocation)
        }
    }
    
    func paDriver(driver: PADriverProtocol!, videoRecordingDidChange event: PADriverVideoRecordingEvent, status: PADriverVideoRecordingStatus) {
        self.recording.value = (event == PADriverVideoRecordingEventStart)
    }
    
    func paDriver(driver: PADriverProtocol!, maxDistanceDidChange current: Float, min: Float, max: Float) {
        self.maxSettings.maxDistance = max
        self.minSettings.maxDistance = min
        self.currentSettings.maxDistance = current
        self.didReceiveAllSettings.value = self.hasReceivedAllSettings()
        self.isSendingSettings.value = !self.hasSendAllSettings()
    }
    
    func paDriver(driver: PADriverProtocol!, maxTiltDidChange current: Float, min: Float, max: Float) {
        self.maxSettings.maxTilt = max
        self.minSettings.maxTilt = min
        self.currentSettings.maxTilt = current
        self.didReceiveAllSettings.value = self.hasReceivedAllSettings()
        self.isSendingSettings.value = !self.hasSendAllSettings()
    }
    
    func paDriver(driver: PADriverProtocol!, maxAltitudeDidChange current: Float, min: Float, max: Float) {
        self.maxSettings.maxAltitude = max
        self.minSettings.maxAltitude = min
        self.currentSettings.maxAltitude = current
        self.didReceiveAllSettings.value = self.hasReceivedAllSettings()
        self.isSendingSettings.value = !self.hasSendAllSettings()
    }
    
    func paDriver(driver: PADriverProtocol!, cameraSettingsDidChange fov: Float, maxPan: Float, minPan: Float, maxTilt: Float, minTilt: Float) {
        self.maxSettings.cameraPan = maxPan
        self.minSettings.cameraPan = minPan
        
        self.maxSettings.cameraTilt = maxTilt
        self.minSettings.cameraTilt = minTilt
        
//        print("pan min: \(minPan) max \(maxPan)")
//        print("tilt min: \(minTilt) max \(maxTilt)")
    }
    
    func paDriver(driver: PADriverProtocol!, maxRotationSpeedDidChange current: Float, min: Float, max: Float) {
        self.maxSettings.rotationSpeed = max
        self.minSettings.rotationSpeed = min
        self.currentSettings.rotationSpeed = current
        self.didReceiveAllSettings.value = self.hasReceivedAllSettings()
        self.isSendingSettings.value = !self.hasSendAllSettings()
    }
    
    func paDriver(driver: PADriverProtocol!, maxVerticalSpeedDidChange current: Float, min: Float, max: Float) {
        self.maxSettings.verticalSpeed = max
        self.minSettings.verticalSpeed = min
        self.currentSettings.verticalSpeed = current
        self.didReceiveAllSettings.value = self.hasReceivedAllSettings()
        self.isSendingSettings.value = !self.hasSendAllSettings()
    }
    
    func paDriver(driver: PADriverProtocol!, pictureRecordingDidChange event: PADriverPictureRecordingEvent, status: PADriverPictureRecordingStatus) {
        
    }
    
    func paDriver(driver: PADriverProtocol!, pictureFormatDidChange format: PADriverPictureFormat) {
        
    }
    
    func paDriver(driver: PADriverProtocol!, gpsStatusDidChanged good: Bool) {
        self.safeGPS.value = good
    }
    
    func paDriver(driver: PADriverProtocol!, returnHomeStateChanged: PADriverReturnHomeState) {
        var isGoingHome = false
        
        switch returnHomeStateChanged {
        case PADriverReturnHomeStateInProgress, PADriverReturnHomeStatePending:
            isGoingHome = true
        default:
            break
        }
        
        goHome.value = isGoingHome
    }
    
    func paDriver(driver: PADriverProtocol!, calibrationState required: Bool) {
        
    }
    
    func paDriver(driver: PADriverProtocol!, bankedTurnDidChange bankedTurnEnabled: Bool) {
        bankedTurn.value = bankedTurnEnabled
    }
    
    func paDriver(driver: PADriverProtocol!, wifiOutdoor outdoor: Bool) {
        wifiOutdoor.value = outdoor
    }
    
    func paDriver(driver: PADriverProtocol!, roll: Bool, pitch: Bool) {
        stabilizationRoll.value = roll
        stabilizationPitch.value = pitch
    }
    
    func paDriver(driver: PADriverProtocol!, videoFrameRate rate: PADriverVideoFrameRate) {
        videoFrameRate.value = VideoFrameRate.fromParrot(rate)
    }
    
    func paDriver(driver: PADriverProtocol!, returnHomeDelay delay: UInt) {
        returnHomeDelay.value = Int(delay)
    }
    
}
