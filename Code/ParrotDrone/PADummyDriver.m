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

#import "PADummyDriver.h"

@import UIKit;

#define ALog(fmt, ...) NSLog((@"%s " fmt), __PRETTY_FUNCTION__, ##__VA_ARGS__)

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface PADummyDriver ()

@property (nonatomic, assign) PADriverDeviceState connectionState;
@property (nonatomic, assign) PADriverFlyingState flyingState;
@property (nonatomic, strong) NSTimer *batteryTimer;
@property (nonatomic, strong) NSTimer *gpsTimer;
@property (nonatomic, strong) NSTimer *speedTimer;
@property (nonatomic, strong) NSTimer *altitudeTimer;
@property (nonatomic, strong) NSTimer *cameraTimer;
@property (nonatomic, strong) NSTimer *loosingConnectionTimer;
@property (nonatomic, assign, getter=isRecording) BOOL recording;
@property (nonatomic, assign) PADriverPictureFormat pictureFormat;

@property (nonatomic, assign) BOOL isGoingHome;
@property (nonatomic, assign) BOOL simulateLoosingConnection;

@end


////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation PADummyDriver

////////////////////////////////////////////////////////////////////////////////////////////////////
- (instancetype)init {
    self = [super init];
    if (self) {
        self.connectionState = PADriverDeviceStateStopped;
        self.recording = NO;
        self.pictureFormat = PADriverPictureFormatJPEG;
        
        self.simulateLoosingConnection = NO;
        self.isGoingHome = NO;
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)dispatchAfter:(NSTimeInterval)delay block:(dispatch_block_t)block {
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC);
    dispatch_after(time, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
//    dispatch_after(time, dispatch_get_main_queue(), block);
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger)randomInteger:(int)min max:(int)max {
    return (NSInteger)min + arc4random_uniform(max - min + 1);
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (double)randomDouble:(double)min max:(double)max {
    return (double)min + arc4random_uniform(max - min + 1);
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger)randomBool {
    u_int32_t randomNumber = (arc4random() % ((unsigned)RAND_MAX + 1));
    if(randomNumber % 5 ==0)
        return YES;
    return NO;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)connect {
    [self dispatchAfter:1 block:^{
        self.connectionState = PADriverDeviceStateRunning;
        [self.delegate paDriver:self connectionDidChange:self.connectionState];
        [self.delegate paDriver:self maxDistanceDidChange:10 min:10 max:2000];
        [self.delegate paDriver:self maxTiltDidChange:5 min:5 max:35];
        [self.delegate paDriver:self maxAltitudeDidChange:0.5 min:2.59 max:150];
        [self.delegate paDriver:self cameraSettingsDidChange:0 maxPan:35 minPan:-35 maxTilt:-83 minTilt:17];
        [self.delegate paDriver:self maxRotationSpeedDidChange:50 min:10 max:200];
        [self.delegate paDriver:self maxVerticalSpeedDidChange:0.5 min:0.5 max:6];
        [self.delegate paDriver:self gpsStatusDidChanged:YES];
        [self.delegate paDriver:self returnHomeDelay:60];
        [self.delegate paDriver:self videoFrameRate:PADriverVideoFrameRate24];
        [self.delegate paDriver:self bankedTurnDidChange:YES];
        [self.delegate paDriver:self wifiOutdoor:YES];
        [self.delegate paDriver:self roll:YES pitch:YES];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self beginSimulation];
        });

    }];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)disconnect {
    self.connectionState = PADriverDeviceStateStopped;
    [self.delegate paDriver:self connectionDidChange:self.connectionState];
    [self stopSimulation];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)simulateDiconnect {
    self.connectionState = PADriverDeviceStateStopped;
    [self.delegate paDriver:self connectionDidChange:self.connectionState];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setCameraOrientation:(NSInteger)tilt pan:(NSInteger)pan {
//    ALog(@"%@ pan %@", @(tilt), @(pan));
    
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)emergency {
    self.flyingState = PADriverFlyingStateEmergency;
    [self.delegate paDriver:self flyingStateDidChange:self.flyingState];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)takeOff {
    self.flyingState = PADriverFlyingStateHovering;
    [self.delegate paDriver:self flyingStateDidChange:self.flyingState];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)land {
    self.flyingState = PADriverFlyingStateLanded;
    [self.delegate paDriver:self flyingStateDidChange:self.flyingState];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)takePicture {
    [self.delegate paDriver:self pictureRecordingDidChange:PADriverPictureRecordingEventTaken status:PADriverPictureRecordingStatusOK];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)sendVideoStreamMode:(PADriverVideoStreamMode)mode {
    
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setPitch:(NSInteger)pitch {
    ALog(@"%@", @(pitch));
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setRoll:(NSInteger)roll {
    ALog(@"%@", @(roll));
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setYaw:(NSInteger)yaw {
    ALog(@"%@", @(yaw));
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setGaz:(NSInteger)gaz {
    ALog(@"%@", @(gaz));
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setFlag:(NSUInteger)flag {
    
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)downloadMedias {
    
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)cancelDownloadMedias {
    
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)startRecordingMovie:(BOOL)start {
    [self.delegate paDriver:self videoRecordingDidChange:start ? PADriverVideoRecordingEventStart : PADriverVideoRecordingEventStop
                     status:PADriverVideoRecordingStatusOK];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)settingsNoFlyOverMaxDistance:(BOOL)noFly {
    ALog(@"%@", @(noFly));
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)settingsPilotingMaxDistance:(float)maxDistance {
    ALog(@"%@", @(maxDistance));
    
    [self.delegate paDriver:self maxDistanceDidChange:maxDistance min:10 max:2000];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)settingsPilotingMaxAltitude:(float)maxAltitude {
    ALog(@"%@", @(maxAltitude));
    
    [self.delegate paDriver:self maxAltitudeDidChange:maxAltitude min:2.59 max:150];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)pilotingGoHome:(BOOL)start {
    self.isGoingHome = start;
    [self.delegate paDriver:self returnHomeStateChanged:self.isGoingHome ? PADriverReturnHomeStateInProgress : PADriverReturnHomeStateAvailable];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)pilotingFlatTrim {
    
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)settingsPilotingMaxTilt:(float)tilt {
    ALog(@"%@", @(tilt));
    
    [self.delegate paDriver:self maxTiltDidChange:tilt min:5 max:35];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)settingsPilotingMaxVerticalSpeed:(float)speed {
    ALog(@"%@", @(speed));
    
    [self dispatchAfter:1 block:^{
        [self.delegate paDriver:self maxVerticalSpeedDidChange:speed min:0.5 max:6];
    }];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)sendGpsPosition:(double)latitude longitude:(double)longitude altitude:(double)altitude horizontalAccuracy:(double)horizontalAccuracy verticalAccuracy:(double)verticalAccuracy {
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)settingsPilotingMaxRotationSpeed:(float)rotation {
    ALog(@"%@", @(rotation));
    
    [self.delegate paDriver:self maxRotationSpeedDidChange:rotation min:10 max:200];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)settingsPilotingOutdoor:(BOOL)outdoor {
    ALog(@"%@", @(outdoor));
    [self.delegate paDriver:self wifiOutdoor:outdoor];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)settingsReturnHomeDelay:(NSUInteger)delay {
    ALog(@"%@", @(delay));
    [self.delegate paDriver:self returnHomeDelay:delay];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)hasCamera {
    return YES;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)settingsSetCountry:(NSString *)isoCode {
    
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)settingsSetPictureFormat:(PADriverPictureFormat)format {
    self.pictureFormat = format;
    [self.delegate paDriver:self pictureFormatDidChange:self.pictureFormat];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)settingsTimelapse:(BOOL)enabled interval:(float)interval {
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)sendSetPiloting:(BOOL)piloting {
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)settingsReturnHomeType:(PADriverReturnHomeType)type {
    
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)moveBy:(float)dX dY:(float)dY dZ:(float)dZ rotation:(float)rotation {
    
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)sendPilotingBankedTurn:(BOOL)bankedTurn {
    [self.delegate paDriver:self bankedTurnDidChange:bankedTurn];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)settingsVideoRecordingMode:(BOOL)bestQuality {
    
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)settingsVideoStabilizationMode:(BOOL)roll pitch:(BOOL)pitch {
    [self.delegate paDriver:self roll:roll pitch:roll];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)settingsVideoRecordingResolution:(PADriverVideoResolution)resolution {
    
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)settingsVideoFrameRate:(PADriverVideoFrameRate)frameRate {
    [self.delegate paDriver:self videoFrameRate:frameRate];
}


////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Simulations

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)beginSimulation {
    self.batteryTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(batterySimulation) userInfo:nil repeats:YES];
    self.speedTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(speedSimulation) userInfo:nil repeats:YES];
    self.gpsTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(gpsSimulation) userInfo:nil repeats:YES];
    self.altitudeTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(altitudeSimulation) userInfo:nil repeats:YES];
    
    if (self.simulateLoosingConnection) {
        self.loosingConnectionTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(loosingConnectionSimulation) userInfo:nil repeats:YES];
    }
    
    self.cameraTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(cameraSimulation) userInfo:nil repeats:YES];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)stopSimulation {
    [self.speedTimer invalidate];
    [self.batteryTimer invalidate];
    [self.gpsTimer invalidate];
    [self.altitudeTimer invalidate];
    [self.loosingConnectionTimer invalidate];
    [self.cameraTimer invalidate];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)loosingConnectionSimulation {
    [self simulateDiconnect];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)cameraSimulation {
    UIImage *image = [UIImage imageNamed:@"HomeBackground"];
    [self.delegate paDriver:self didReceiveImage:image];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)batterySimulation {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        [self.delegate paDriver:self batteryDidChange:(int)[self randomInteger:0 max:20]];
        [self.delegate paDriver:self batteryDidChange:(int)[self randomInteger:0 max:100]];
    });
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)altitudeSimulation {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.delegate paDriver:self altitudeDidChange:(double)[self randomInteger:0 max:400]];
    });
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)gpsSimulation {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.delegate paDriver:self gpsSattelitesNumberDidChange:(int)[self randomInteger:0 max:15]];
        [self.delegate paDriver:self gpsStatusDidChanged:[self randomBool]];
        
        [self.delegate paDriver:self positionDidChangeWithLatitude:[self randomDouble:-90 max:90]
                      longitude:[self randomDouble:-180 max:180]
                       altitude:(double)[self randomInteger:0 max:400]];
    });
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)speedSimulation {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.delegate paDriver:self speedDidChangeWithSpeedX:(int)[self randomInteger:0 max:16] speedY:(int)[self randomInteger:0 max:30] speedZ:(int)[self randomInteger:0 max:25]];
    });
}

@end
