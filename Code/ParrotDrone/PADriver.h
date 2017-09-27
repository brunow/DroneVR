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

#import <libARController/ARController.h>
#import <libARDiscovery/ARDISCOVERY_BonjourDiscovery.h>
#import "PaMediaModel.h"

@protocol PADriverDelegate;
@class UIImage;

typedef enum {
    PADriverDeviceStateStopped = 0,
    PADriverDeviceStateStarting,
    PADriverDeviceStateRunning,
    PADriverDeviceStatePause,
    PADriverDeviceStateStopping
} PADriverDeviceState;

typedef enum {
    PADriverReturnHomeStateAvailable = 0,
    PADriverReturnHomeStateInProgress,
    PADriverReturnHomeStateUnavailable,
    PADriverReturnHomeStatePending
} PADriverReturnHomeState;

typedef enum {
    PADriverFlyingStateLanded = 0,
    PADriverFlyingStateTakingOff,
    PADriverFlyingStateHovering,
    PADriverFlyingStateFlying,
    PADriverFlyingStateLanding,
    PADriverFlyingStateEmergency
} PADriverFlyingState;

typedef enum {
    PADriverVideoRecordingEventStart,
    PADriverVideoRecordingEventStop,
    PADriverVideoRecordingEventFailed
} PADriverVideoRecordingEvent;

typedef enum {
    PADriverPictureRecordingEventTaken,
    PADriverPictureRecordingEventFailed
} PADriverPictureRecordingEvent;

typedef enum {
    PADriverPictureRecordingStatusOK,
    PADriverPictureRecordingStatusUnknown,
    PADriverPictureRecordingStatusBusy,
    PADriverPictureRecordingStatusNotAvailable,
    PADriverPictureRecordingStatusMemoryFull,
    PADriverPictureRecordingStatusLowBattery
} PADriverPictureRecordingStatus;

typedef enum {
    PADriverVideoRecordingStatusOK,
    PADriverVideoRecordingStatusUnknown,
    PADriverVideoRecordingStatusBusy,
    PADriverVideoRecordingStatusNotAvailable,
    PADriverVideoRecordingStatusMemoryFull,
    PADriverVideoRecordingStatusLowBattery,
    PADriverVideoRecordingStatusAutoStopped
} PADriverVideoRecordingStatus;

typedef enum {
    PADriverPictureFormatRAW,
    PADriverPictureFormatJPEG,
    PADriverPictureFormatSNAPSHOT
} PADriverPictureFormat;

typedef enum {
    PADriverReturnHomeTypeTAKEOFF,
    PADriverReturnHomeTypePILOT
} PADriverReturnHomeType;

typedef enum {
    PADriverVideoStreamModeLowLatency,
    PADriverVideoStreamModeHighReliability,
    PADriverVideoStreamModeHighReliabilityLowFramerate
} PADriverVideoStreamMode;

typedef enum {
    PADriverVideoResolutionModeBestRecording,
    PADriverVideoResolutionModeBestStreaming
} PADriverVideoResolution;

typedef enum {
    PADriverVideoFrameRate24,
    PADriverVideoFrameRate25,
    PADriverVideoFrameRate30
} PADriverVideoFrameRate;

@protocol PADriverProtocol <NSObject>

@property (nonatomic, weak) id<PADriverDelegate>delegate;

- (void)connect;
- (void)disconnect;
- (PADriverDeviceState)connectionState;
- (PADriverFlyingState)flyingState;

- (void)setCameraOrientation:(NSInteger)tilt pan:(NSInteger)pan;
- (void)emergency;
- (void)takeOff;
- (void)land;
- (void)takePicture;
- (void)setPitch:(NSInteger)pitch;
- (void)setRoll:(NSInteger)roll;
- (void)setYaw:(NSInteger)yaw;
- (void)setGaz:(NSInteger)gaz;
- (void)setFlag:(NSUInteger)flag;
- (void)downloadMedias;
- (void)cancelDownloadMedias;
- (void)startRecordingMovie:(BOOL)start;
- (void)pilotingGoHome:(BOOL)start;
- (void)pilotingFlatTrim;
- (void)settingsNoFlyOverMaxDistance:(BOOL)noFly;
- (void)settingsPilotingMaxDistance:(float)maxDistance;
- (void)settingsPilotingMaxAltitude:(float)maxAltitude;
- (void)settingsPilotingMaxTilt:(float)tilt;
- (void)settingsPilotingMaxVerticalSpeed:(float)speed;
- (void)settingsPilotingMaxRotationSpeed:(float)rotation;
- (void)settingsPilotingOutdoor:(BOOL)outdoor;
- (void)settingsReturnHomeDelay:(NSUInteger)delay;
- (BOOL)hasCamera;
- (void)settingsSetCountry:(NSString *)isoCode;
- (void)settingsSetPictureFormat:(PADriverPictureFormat)format;
- (void)sendSetPiloting:(BOOL)piloting;
- (void)settingsTimelapse:(BOOL)enabled interval:(float)interval;
- (void)settingsReturnHomeType:(PADriverReturnHomeType)type;
- (void)sendVideoStreamMode:(PADriverVideoStreamMode)mode;
- (void)moveBy:(float)dX dY:(float)dY dZ:(float)dZ rotation:(float)rotation;
- (void)sendGpsPosition:(double)latitude longitude:(double)longitude altitude:(double)altitude horizontalAccuracy:(double)horizontalAccuracy verticalAccuracy:(double)verticalAccuracy;
- (void)sendPilotingBankedTurn:(BOOL)bankedTurn;
- (void)settingsVideoRecordingMode:(BOOL)bestQuality;
- (void)settingsVideoStabilizationMode:(BOOL)roll pitch:(BOOL)pitch;
- (void)settingsVideoRecordingResolution:(PADriverVideoResolution)resolution;
- (void)settingsVideoFrameRate:(PADriverVideoFrameRate)frameRate;

@end

@protocol PADriverDelegate <NSObject>

- (void)paDriver:(id <PADriverProtocol>)driver connectionDidChange:(PADriverDeviceState)state;
- (void)paDriver:(id <PADriverProtocol>)driver batteryDidChange:(int)batteryPercentage;
- (void)paDriver:(id <PADriverProtocol>)driver flyingStateDidChange:(PADriverFlyingState)state;
- (void)paDriver:(id <PADriverProtocol>)driver gpsSattelitesNumberDidChange:(NSUInteger)satteliesNumber;
- (void)paDriver:(id <PADriverProtocol>)driver cameraCenterOrientationTilt:(float)tilt pan:(float)pan;
- (void)paDriver:(id <PADriverProtocol>)driver altitudeDidChange:(double)altitude;
- (void)paDriver:(id <PADriverProtocol>)driver positionDidChangeWithLatitude:(double)latitude longitude:(double)longitude altitude:(double)altitude;
- (void)paDriver:(id <PADriverProtocol>)driver speedDidChangeWithSpeedX:(float)speedX speedY:(float)speedY speedZ:(float)speedZ;
- (void)paDriver:(id <PADriverProtocol>)driver didFoundMatchingMedias:(NSUInteger)nbMedias;
- (void)paDriver:(id <PADriverProtocol>)driver videoRecordingDidChange:(PADriverVideoRecordingEvent)event status:(PADriverVideoRecordingStatus)status;
- (void)paDriver:(id <PADriverProtocol>)driver maxDistanceDidChange:(float)current min:(float)min max:(float)max;
- (void)paDriver:(id <PADriverProtocol>)driver maxTiltDidChange:(float)current min:(float)min max:(float)max;
- (void)paDriver:(id <PADriverProtocol>)driver maxAltitudeDidChange:(float)current min:(float)min max:(float)max;
- (void)paDriver:(id <PADriverProtocol>)driver cameraSettingsDidChange:(float)fov maxPan:(float)maxPan minPan:(float)minPan maxTilt:(float)maxTilt minTilt:(float)minTilt;
- (void)paDriver:(id <PADriverProtocol>)driver maxVerticalSpeedDidChange:(float)current min:(float)min max:(float)max;
- (void)paDriver:(id <PADriverProtocol>)driver maxRotationSpeedDidChange:(float)current min:(float)min max:(float)max;
- (void)paDriver:(id <PADriverProtocol>)driver pictureRecordingDidChange:(PADriverPictureRecordingEvent)event status:(PADriverPictureRecordingStatus)status;
- (void)paDriver:(id <PADriverProtocol>)driver pictureFormatDidChange:(PADriverPictureFormat)format;
- (void)paDriver:(id <PADriverProtocol>)driver gpsStatusDidChanged:(BOOL)good;
- (void)paDriver:(id<PADriverProtocol>)driver returnHomeStateChanged:(PADriverReturnHomeState)returnHomeState;
- (void)paDriver:(id <PADriverProtocol>)driver calibrationState:(BOOL)required;
- (void)paDriver:(id <PADriverProtocol>)driver bankedTurnDidChange:(BOOL)bankedTurn;
- (void)paDriver:(id <PADriverProtocol>)driver returnHomeDelay:(NSUInteger)delay;
- (void)paDriver:(id <PADriverProtocol>)driver videoFrameRate:(PADriverVideoFrameRate)frameRate;
- (void)paDriver:(id <PADriverProtocol>)driver wifiOutdoor:(BOOL)wifiOutdoor;
- (void)paDriver:(id <PADriverProtocol>)driver roll:(BOOL)roll pitch:(BOOL)pitch;

// Media
- (void)paDriver:(id <PADriverProtocol>)driver media:(PaMediaModel *)media downloadDidProgress:(int)progress;
- (void)paDriver:(id <PADriverProtocol>)driver mediaDownloadDidFinish:(PaMediaModel *)media;

// Camera
- (BOOL)paDriver:(id <PADriverProtocol>)driver configureDecoder:(ARCONTROLLER_Stream_Codec_t)codec;
- (BOOL)paDriver:(id <PADriverProtocol>)driver didReceiveFrame:(ARCONTROLLER_Frame_t*)frame;
- (void)paDriver:(id <PADriverProtocol>)driver didReceiveImage:(UIImage *)image;

@end
