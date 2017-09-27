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

#import "PAMiniDroneDriver.h"

#define FTP_PORT 21

// Others
#import "PASDCardModule.h"
#import <libARController/ARController.h>
#import <libARDiscovery/ARDISCOVERY_BonjourDiscovery.h>

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface PAMiniDroneDriver () <PASDCardModuleDelegate>

@property (nonatomic, assign) ARCONTROLLER_Device_t *deviceController;
@property (nonatomic, assign) ARService *service;
@property (nonatomic, strong) PASDCardModule *sdCardModule;
@property (nonatomic, assign) PADriverDeviceState connectionState;
@property (nonatomic, assign) PADriverFlyingState flyingState;
@property (nonatomic, strong) NSString *currentRunId;
@property (nonatomic, assign) NSInteger prevRoll;
@property (nonatomic, assign) NSInteger prevPitch;
@property (nonatomic, assign) PADriverPictureFormat pictureFormat;

@end


////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation PAMiniDroneDriver

////////////////////////////////////////////////////////////////////////////////////////////////////
- (instancetype)initWithService:(ARService *)service {
    self = [super init];
    if (self) {
        _service = service;
        _flyingState = PADriverFlyingStateLanded;
        self.pictureFormat = PADriverPictureFormatJPEG;
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)dealloc {
    if (_deviceController) {
        ARCONTROLLER_Device_Delete(&_deviceController);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)connect {
    if (!_deviceController) {
        // call createDeviceControllerWithService in background
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // if the product type of the service matches with the supported types
            eARDISCOVERY_PRODUCT product = _service.product;
            eARDISCOVERY_PRODUCT_FAMILY family = ARDISCOVERY_getProductFamily(product);
            if (family == ARDISCOVERY_PRODUCT_FAMILY_MINIDRONE) {
                // create the device controller
                [self createDeviceControllerWithService:_service];
                //[self createSDCardModule];
            }
        });
    } else {
        ARCONTROLLER_Device_Start (_deviceController);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)disconnect {
    ARCONTROLLER_Device_Stop (_deviceController);
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setCameraOrientation:(NSInteger)tilt pan:(NSInteger)pan {
    
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)dispatchAfter:(NSTimeInterval)delay block:(dispatch_block_t)block {
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC);
    dispatch_after(time, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
    //    dispatch_after(time, dispatch_get_main_queue(), block);
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)emergency {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
        _deviceController->miniDrone->sendPilotingEmergency(_deviceController->miniDrone);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)takeOff {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
        _deviceController->miniDrone->sendPilotingTakeOff(_deviceController->miniDrone);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)land {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
        _deviceController->miniDrone->sendPilotingLanding(_deviceController->miniDrone);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)takePicture {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
        // RollingSpider (not evo) are still using old deprecated command
        if (_service.product == ARDISCOVERY_PRODUCT_MINIDRONE) {
            _deviceController->miniDrone->sendMediaRecordPicture(_deviceController->miniDrone, 0);
        } else {
            _deviceController->miniDrone->sendMediaRecordPictureV2(_deviceController->miniDrone);
        }
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setPitch:(NSInteger)pitch {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
//        NSLog(@"pitch %d", pitch);
        self.prevPitch = pitch;
        [self setFlagForCurrentState];
        _deviceController->miniDrone->setPilotingPCMDPitch(_deviceController->miniDrone, pitch);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setRoll:(NSInteger)roll {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
//        NSLog(@"roll %d", roll);
        self.prevRoll = roll;
        [self setFlagForCurrentState];
        _deviceController->miniDrone->setPilotingPCMDRoll(_deviceController->miniDrone, roll);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setYaw:(NSInteger)yaw {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
//        NSLog(@"yaw %d", yaw);
        _deviceController->miniDrone->setPilotingPCMDYaw(_deviceController->miniDrone, yaw);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setGaz:(NSInteger)gaz {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
//        NSLog(@"gaz %d", gaz);
        _deviceController->miniDrone->setPilotingPCMDGaz(_deviceController->miniDrone, gaz);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setFlag:(NSUInteger)flag {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
        _deviceController->miniDrone->setPilotingPCMDFlag(_deviceController->miniDrone, flag);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)downloadMedias {
    if (!_sdCardModule) {
        [self createSDCardModule];
    }
    if (_currentRunId && ![_currentRunId isEqualToString:@""]) {
        [_sdCardModule getFlightMedias:_currentRunId];
    } else {
        [_sdCardModule getTodaysFlightMedias];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)cancelDownloadMedias {
    [_sdCardModule cancelGetMedias];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)startRecordingMovie:(BOOL)start {
    
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)settingsNoFlyOverMaxDistance:(BOOL)noFly {
    
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)settingsPilotingMaxDistance:(float)maxDistance {
    [self.delegate paDriver:self maxDistanceDidChange:10 min:10 max:2000];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)settingsPilotingMaxAltitude:(float)maxAltitude {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
        _deviceController->miniDrone->sendPilotingSettingsMaxAltitude(_deviceController->miniDrone, maxAltitude);
        [self dispatchAfter:3 block:^{
            [self.delegate paDriver:self maxAltitudeDidChange:4 min:2.6 max:10];
        }];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)pilotingGoHome:(BOOL)start {
    
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)sendVideoStreamMode:(PADriverVideoStreamMode)mode {
    
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)pilotingFlatTrim {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
        _deviceController->miniDrone->sendPilotingFlatTrim(_deviceController->miniDrone);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)settingsPilotingMaxTilt:(float)tilt {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
        NSLog(@"tilt %f", tilt);
        _deviceController->miniDrone->sendPilotingSettingsMaxTilt(_deviceController->miniDrone, tilt);
        
        [self dispatchAfter:3 block:^{
            [self.delegate paDriver:self maxTiltDidChange:5 min:5 max:25];
        }];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)settingsPilotingMaxVerticalSpeed:(float)speed {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
        _deviceController->miniDrone->sendSpeedSettingsMaxVerticalSpeed(_deviceController->miniDrone, speed);
        
        [self dispatchAfter:3 block:^{
            [self.delegate paDriver:self maxVerticalSpeedDidChange:0.5 min:0.5 max:2];
        }];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)settingsPilotingMaxRotationSpeed:(float)rotation {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
        _deviceController->miniDrone->sendSpeedSettingsMaxRotationSpeed(_deviceController->miniDrone, rotation);
        
        [self dispatchAfter:3 block:^{
            [self.delegate paDriver:self maxRotationSpeedDidChange:50 min:10 max:360];
        }];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)settingsPilotingOutdoor:(BOOL)outdoor {
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)settingsSetCountry:(NSString *)isoCode {
    
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)settingsReturnHomeDelay:(NSUInteger)delay {
    
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
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
        _deviceController->common->sendControllerIsPiloting(_deviceController->common, piloting);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)settingsReturnHomeType:(PADriverReturnHomeType)type {
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)hasCamera {
    return NO;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)moveBy:(float)dX dY:(float)dY dZ:(float)dZ rotation:(float)rotation {
    
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)sendGpsPosition:(double)latitude longitude:(double)longitude altitude:(double)altitude horizontalAccuracy:(double)horizontalAccuracy verticalAccuracy:(double)verticalAccuracy {
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
#pragma mark Device controller callbacks

// called when the state of the device controller has changed
static void stateChanged (eARCONTROLLER_DEVICE_STATE newState, eARCONTROLLER_ERROR error, void *customData) {
    PAMiniDroneDriver *miniDrone = (__bridge PAMiniDroneDriver*)customData;
    if (miniDrone != nil) {
        switch (newState) {
            case ARCONTROLLER_DEVICE_STATE_RUNNING:
                break;
            case ARCONTROLLER_DEVICE_STATE_STOPPED:
                break;
            default:
                break;
        }
        miniDrone.connectionState = [PAMiniDroneDriver convertDeviceParrotState:newState];
        [miniDrone.delegate paDriver:miniDrone connectionDidChange:[PAMiniDroneDriver convertDeviceParrotState:newState]];
        [miniDrone.delegate paDriver:miniDrone maxDistanceDidChange:10 min:10 max:2000];
        [miniDrone.delegate paDriver:miniDrone maxTiltDidChange:5 min:5 max:25];
        [miniDrone.delegate paDriver:miniDrone maxAltitudeDidChange:4 min:2.6 max:10];
        [miniDrone.delegate paDriver:miniDrone cameraSettingsDidChange:0 maxPan:0 minPan:0 maxTilt:0 minTilt:0];
        [miniDrone.delegate paDriver:miniDrone maxRotationSpeedDidChange:50 min:10 max:360];
        [miniDrone.delegate paDriver:miniDrone maxVerticalSpeedDidChange:0.5 min:0.5 max:2];
        [miniDrone.delegate paDriver:miniDrone gpsStatusDidChanged:YES];
        [miniDrone.delegate paDriver:miniDrone returnHomeDelay:60];
        [miniDrone.delegate paDriver:miniDrone videoFrameRate:PADriverVideoFrameRate24];
        [miniDrone.delegate paDriver:miniDrone bankedTurnDidChange:YES];
        [miniDrone.delegate paDriver:miniDrone wifiOutdoor:YES];
        [miniDrone.delegate paDriver:miniDrone roll:YES pitch:YES];
    }
}

// called when a command has been received from the drone
static void onCommandReceived (eARCONTROLLER_DICTIONARY_KEY commandKey, ARCONTROLLER_DICTIONARY_ELEMENT_t *elementDictionary, void *customData) {
    PAMiniDroneDriver *miniDrone = (__bridge PAMiniDroneDriver*)customData;
    
    // if the command received is a battery state changed
    if ((commandKey == ARCONTROLLER_DICTIONARY_KEY_COMMON_COMMONSTATE_BATTERYSTATECHANGED) &&
        (elementDictionary != NULL)) {
        ARCONTROLLER_DICTIONARY_ARG_t *arg = NULL;
        ARCONTROLLER_DICTIONARY_ELEMENT_t *element = NULL;
        
        HASH_FIND_STR (elementDictionary, ARCONTROLLER_DICTIONARY_SINGLE_KEY, element);
        if (element != NULL) {
            HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_COMMON_COMMONSTATE_BATTERYSTATECHANGED_PERCENT, arg);
            if (arg != NULL) {
                uint8_t battery = arg->value.U8;
                [miniDrone.delegate paDriver:miniDrone batteryDidChange:battery];
            }
        }
    }
    // if the command received is a battery state changed
    else if ((commandKey == ARCONTROLLER_DICTIONARY_KEY_MINIDRONE_PILOTINGSTATE_FLYINGSTATECHANGED) &&
             (elementDictionary != NULL)) {
        ARCONTROLLER_DICTIONARY_ARG_t *arg = NULL;
        ARCONTROLLER_DICTIONARY_ELEMENT_t *element = NULL;
        
        HASH_FIND_STR (elementDictionary, ARCONTROLLER_DICTIONARY_SINGLE_KEY, element);
        if (element != NULL) {
            HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_MINIDRONE_PILOTINGSTATE_FLYINGSTATECHANGED_STATE, arg);
            if (arg != NULL) {
                eARCOMMANDS_ARDRONE3_PILOTINGSTATE_FLYINGSTATECHANGED_STATE state = arg->value.I32;
                miniDrone.flyingState = [PAMiniDroneDriver convertFlyingParrotState:state];
                [miniDrone.delegate paDriver:miniDrone flyingStateDidChange:miniDrone.flyingState];
            }
        }
    }
    // if the command received is a run id changed
    else if ((commandKey == ARCONTROLLER_DICTIONARY_KEY_COMMON_RUNSTATE_RUNIDCHANGED) &&
             (elementDictionary != NULL)) {
        ARCONTROLLER_DICTIONARY_ARG_t *arg = NULL;
        ARCONTROLLER_DICTIONARY_ELEMENT_t *element = NULL;
        
        HASH_FIND_STR (elementDictionary, ARCONTROLLER_DICTIONARY_SINGLE_KEY, element);
        if (element != NULL) {
            HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_COMMON_RUNSTATE_RUNIDCHANGED_RUNID, arg);
            if (arg != NULL) {
                char * runId = arg->value.String;
                if (runId != NULL) {
                    miniDrone.currentRunId = [NSString stringWithUTF8String:runId];
                }
            }
        }
    }
    else if ((commandKey == ARCONTROLLER_DICTIONARY_KEY_COMMON_SETTINGSSTATE_PRODUCTNAMECHANGED) && (elementDictionary != NULL)) {
        ARCONTROLLER_DICTIONARY_ARG_t *arg = NULL;
        ARCONTROLLER_DICTIONARY_ELEMENT_t *element = NULL;
        HASH_FIND_STR (elementDictionary, ARCONTROLLER_DICTIONARY_SINGLE_KEY, element);
        if (element != NULL) {
            HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_COMMON_SETTINGSSTATE_PRODUCTNAMECHANGED_NAME, arg);
            if (arg != NULL) {
                char * name = arg->value.String;
                NSString *stringName = [NSString stringWithUTF8String:name];
                NSLog(@"%@", stringName);
            }
        }
    }
}


////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark SDCardModuleDelegate

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)sdcardModule:(PASDCardModule*)module didFoundMatchingMedias:(NSUInteger)nbMedias {
    [self.delegate paDriver:self didFoundMatchingMedias:nbMedias];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)sdcardModule:(PASDCardModule*)module media:(PaMediaModel *)media downloadDidProgress:(int)progress {
    [self.delegate paDriver:self media:media downloadDidProgress:progress];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)sdcardModule:(PASDCardModule*)module mediaDownloadDidFinish:(PaMediaModel*)media {
    [self.delegate paDriver:self mediaDownloadDidFinish:media];
}


////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (PADriverDeviceState)convertDeviceParrotState:(eARCONTROLLER_DEVICE_STATE)state {
    NSLog(@"convertDeviceParrotState %d", state);
    
    switch (state) {
        case ARCONTROLLER_DEVICE_STATE_STOPPED:
            return PADriverDeviceStateStopped;
            break;
        case ARCONTROLLER_DEVICE_STATE_STARTING:
            return PADriverDeviceStateStarting;
            break;
        case ARCONTROLLER_DEVICE_STATE_RUNNING:
            return PADriverDeviceStateRunning;
            break;
        case ARCONTROLLER_DEVICE_STATE_PAUSED:
            return PADriverDeviceStatePause;
            break;
        case ARCONTROLLER_DEVICE_STATE_STOPPING:
            return PADriverDeviceStateStopping;
            break;
            
        default:
            break;
    }
    
    return PADriverDeviceStateStopped;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (PADriverFlyingState)convertFlyingParrotState:(eARCOMMANDS_ARDRONE3_PILOTINGSTATE_FLYINGSTATECHANGED_STATE)state {
    switch (state) {
        case ARCOMMANDS_ARDRONE3_PILOTINGSTATE_FLYINGSTATECHANGED_STATE_LANDED:
            return PADriverFlyingStateLanded;
            break;
        case ARCOMMANDS_ARDRONE3_PILOTINGSTATE_FLYINGSTATECHANGED_STATE_TAKINGOFF:
            return PADriverFlyingStateTakingOff;
            break;
        case ARCOMMANDS_ARDRONE3_PILOTINGSTATE_FLYINGSTATECHANGED_STATE_HOVERING:
            return PADriverFlyingStateHovering;
            break;
        case ARCOMMANDS_ARDRONE3_PILOTINGSTATE_FLYINGSTATECHANGED_STATE_FLYING:
            return PADriverFlyingStateFlying;
            break;
        case ARCOMMANDS_ARDRONE3_PILOTINGSTATE_FLYINGSTATECHANGED_STATE_LANDING:
            return PADriverFlyingStateLanding;
            break;
        case ARCOMMANDS_ARDRONE3_PILOTINGSTATE_FLYINGSTATECHANGED_STATE_EMERGENCY:
            return PADriverFlyingStateEmergency;
            break;
            
        default:
            break;
    }
    
    return PADriverFlyingStateLanded;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setFlagForCurrentState {
    if (self.prevRoll == 0 && self.prevPitch == 0) {
        [self setFlag:0];
    } else {
        [self setFlag:1];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)createDeviceControllerWithService:(ARService*)service {
    // first get a discovery device
    ARDISCOVERY_Device_t *discoveryDevice = [self createDiscoveryDeviceWithService:service];
    
    if (discoveryDevice != NULL) {
        eARCONTROLLER_ERROR error = ARCONTROLLER_OK;
        
        // create the device controller
        _deviceController = ARCONTROLLER_Device_New (discoveryDevice, &error);
        
        // add the state change callback to be informed when the device controller starts, stops...
        if (error == ARCONTROLLER_OK) {
            error = ARCONTROLLER_Device_AddStateChangedCallback(_deviceController, stateChanged, (__bridge void *)(self));
        }
        
        // add the command received callback to be informed when a command has been received from the device
        if (error == ARCONTROLLER_OK) {
            error = ARCONTROLLER_Device_AddCommandReceivedCallback(_deviceController, onCommandReceived, (__bridge void *)(self));
        }
        
        // start the device controller (the callback stateChanged should be called soon)
        if (error == ARCONTROLLER_OK) {
            error = ARCONTROLLER_Device_Start (_deviceController);
        }
        
        // we don't need the discovery device anymore
        ARDISCOVERY_Device_Delete (&discoveryDevice);
        
        // if an error occured, inform the delegate that the state is stopped
        if (error != ARCONTROLLER_OK) {
            [self.delegate paDriver:self connectionDidChange:[PAMiniDroneDriver convertDeviceParrotState:ARCONTROLLER_DEVICE_STATE_STOPPED]];
        }
    } else {
        // if an error occured, inform the delegate that the state is stopped
        [self.delegate paDriver:self connectionDidChange:[PAMiniDroneDriver convertDeviceParrotState:ARCONTROLLER_DEVICE_STATE_STOPPED]];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (ARDISCOVERY_Device_t *)createDiscoveryDeviceWithService:(ARService*)service {
    ARDISCOVERY_Device_t *device = NULL;
    eARDISCOVERY_ERROR errorDiscovery = ARDISCOVERY_OK;
    
    device = ARDISCOVERY_Device_New (&errorDiscovery);
    
    if (errorDiscovery == ARDISCOVERY_OK) {
        // get the ble service from the ARService
        ARBLEService* bleService = service.service;
        
        // create a BLE discovery device
        errorDiscovery = ARDISCOVERY_Device_InitBLE (device, service.product, (__bridge ARNETWORKAL_BLEDeviceManager_t)(bleService.centralManager), (__bridge ARNETWORKAL_BLEDevice_t)(bleService.peripheral));
    }
    
    if (errorDiscovery != ARDISCOVERY_OK) {
        NSLog(@"Discovery error :%s", ARDISCOVERY_Error_ToString(errorDiscovery));
        ARDISCOVERY_Device_Delete(&device);
    }
    
    return device;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)createSDCardModule {
    eARUTILS_ERROR ftpError = ARUTILS_OK;
    ARUTILS_Manager_t *ftpListManager = NULL;
    ARUTILS_Manager_t *ftpQueueManager = NULL;
    
    ftpListManager = ARUTILS_Manager_New(&ftpError);
    if(ftpError == ARUTILS_OK) {
        ftpQueueManager = ARUTILS_Manager_New(&ftpError);
    }
    
    if(ftpError == ARUTILS_OK) {
        ftpError = ARUTILS_Manager_InitBLEFtp(ftpListManager, (__bridge ARUTILS_BLEDevice_t)((ARBLEService *)_service.service).peripheral, FTP_PORT);
    }
    
    if(ftpError == ARUTILS_OK) {
        ftpError = ARUTILS_Manager_InitBLEFtp(ftpQueueManager, (__bridge ARUTILS_BLEDevice_t)((ARBLEService *)_service.service).peripheral, FTP_PORT);
    }
    
    _sdCardModule = [[PASDCardModule alloc] initWithFtpListManager:ftpListManager andFtpQueueManager:ftpQueueManager];
    _sdCardModule.delegate = self;
}

@end
