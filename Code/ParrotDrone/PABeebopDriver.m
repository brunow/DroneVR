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

#import "PABeebopDriver.h"

// Others
#import <libARController/ARController.h>
#import <libARDiscovery/ARDISCOVERY_BonjourDiscovery.h>
#import "PASDCardModule.h"

#define FTP_PORT 21


////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface PABeebopDriver () <PASDCardModuleDelegate>

@property (nonatomic, assign) ARCONTROLLER_Device_t *deviceController;
@property (nonatomic, assign) ARService *service;
@property (nonatomic, strong) PASDCardModule *sdCardModule;
@property (nonatomic, assign) PADriverDeviceState connectionState;
@property (nonatomic, assign) PADriverFlyingState flyingState;
@property (nonatomic, strong) NSString *currentRunId;
@property (nonatomic) dispatch_semaphore_t resolveSemaphore;
@property (nonatomic, assign) NSInteger prevRoll;
@property (nonatomic, assign) NSInteger prevPitch;
@property (nonatomic, assign) uint8_t massStorageID;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation PABeebopDriver

////////////////////////////////////////////////////////////////////////////////////////////////////
- (instancetype)initWithService:(ARService *)service {
    self = [super init];
    if (self) {
        _service = service;
        _flyingState = PADriverFlyingStateLanded;
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
            if (family == ARDISCOVERY_PRODUCT_FAMILY_ARDRONE) {
                // create the device controller
                [self createDeviceControllerWithService:_service];
                [self createSDCardModule];
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
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
        NSLog(@"tilt %@ pan %@", @(tilt), @(pan));
        _deviceController->aRDrone3->setCameraOrientation(_deviceController->aRDrone3, tilt, pan);
//        _deviceController->aRDrone3->sendCameraOrientation(_deviceController->aRDrone3, tilt, pan);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)emergency {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
        _deviceController->aRDrone3->sendPilotingEmergency(_deviceController->aRDrone3);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)takeOff {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
        _deviceController->aRDrone3->sendPilotingTakeOff(_deviceController->aRDrone3);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)land {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
        _deviceController->aRDrone3->sendPilotingLanding(_deviceController->aRDrone3);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)takePicture {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
        _deviceController->aRDrone3->sendMediaRecordPictureV2(_deviceController->aRDrone3);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)settingsSetPictureFormat {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
        _deviceController->aRDrone3->sendPictureSettingsPictureFormatSelection(_deviceController->aRDrone3, ARCOMMANDS_ARDRONE3_PICTURESETTINGS_PICTUREFORMATSELECTION_TYPE_SNAPSHOT);
    }
    //    typedef enum
    //    {
    //    ARCOMMANDS_ARDRONE3_PICTURESETTINGS_PICTUREFORMATSELECTION_TYPE_RAW = 0,    ///< Take raw image
    //    ARCOMMANDS_ARDRONE3_PICTURESETTINGS_PICTUREFORMATSELECTION_TYPE_JPEG,    ///< Take a 4:3 jpeg photo
    //    ARCOMMANDS_ARDRONE3_PICTURESETTINGS_PICTUREFORMATSELECTION_TYPE_SNAPSHOT,    ///< Take a 16:9 snapshot from camera
    //    ARCOMMANDS_ARDRONE3_PICTURESETTINGS_PICTUREFORMATSELECTION_TYPE_JPEG_FISHEYE,    ///< Take jpeg fisheye image only
    //    ARCOMMANDS_ARDRONE3_PICTURESETTINGS_PICTUREFORMATSELECTION_TYPE_MAX
    //    } eARCOMMANDS_ARDRONE3_PICTURESETTINGS_PICTUREFORMATSELECTION_TYPE;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setPitch:(NSInteger)pitch {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
//        NSLog(@"pitch %d", pitch);
        self.prevPitch = pitch;
        [self setFlagForCurrentState];
        _deviceController->aRDrone3->setPilotingPCMDPitch(_deviceController->aRDrone3, pitch);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setRoll:(NSInteger)roll {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
//        NSLog(@"roll %d", roll);
        self.prevRoll = roll;
        [self setFlagForCurrentState];
        _deviceController->aRDrone3->setPilotingPCMDRoll(_deviceController->aRDrone3, roll);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setYaw:(NSInteger)yaw {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
//        NSLog(@"yaw %d", yaw);
        _deviceController->aRDrone3->setPilotingPCMDYaw(_deviceController->aRDrone3, yaw);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setGaz:(NSInteger)gaz {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
//        NSLog(@"gaz %d", gaz);
        _deviceController->aRDrone3->setPilotingPCMDGaz(_deviceController->aRDrone3, gaz);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setFlag:(NSUInteger)flag {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
        _deviceController->aRDrone3->setPilotingPCMDFlag(_deviceController->aRDrone3, flag);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)downloadMedias {
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
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
        _deviceController->aRDrone3->sendMediaRecordVideoV2(_deviceController->aRDrone3, start ? ARCOMMANDS_ARDRONE3_MEDIARECORD_VIDEOV2_RECORD_START : ARCOMMANDS_ARDRONE3_MEDIARECORD_VIDEOV2_RECORD_STOP);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)settingsNoFlyOverMaxDistance:(BOOL)noFly {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
        _deviceController->aRDrone3->sendPilotingSettingsNoFlyOverMaxDistance(_deviceController->aRDrone3, noFly ? 1 : 0);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)settingsPilotingMaxDistance:(float)maxDistance {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
        _deviceController->aRDrone3->sendPilotingSettingsMaxDistance(_deviceController->aRDrone3, maxDistance);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)settingsPilotingMaxAltitude:(float)maxAltitude {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
        _deviceController->aRDrone3->sendPilotingSettingsMaxAltitude(_deviceController->aRDrone3, maxAltitude);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)pilotingGoHome:(BOOL)start {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
        _deviceController->aRDrone3->sendPilotingNavigateHome(_deviceController->aRDrone3, start ? 1 : 0);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)pilotingFlatTrim {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
        _deviceController->aRDrone3->sendPilotingFlatTrim(_deviceController->aRDrone3);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)sendVideoStreamMode:(PADriverVideoStreamMode)mode {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
        eARCOMMANDS_ARDRONE3_MEDIASTREAMING_VIDEOSTREAMMODE_MODE paMode = ARCOMMANDS_ARDRONE3_MEDIASTREAMING_VIDEOSTREAMMODE_MODE_LOW_LATENCY;
        
        switch (mode) {
            case PADriverVideoStreamModeLowLatency:
                paMode = ARCOMMANDS_ARDRONE3_MEDIASTREAMING_VIDEOSTREAMMODE_MODE_LOW_LATENCY;
                break;
            case PADriverVideoStreamModeHighReliability:
                paMode = ARCOMMANDS_ARDRONE3_MEDIASTREAMING_VIDEOSTREAMMODE_MODE_HIGH_RELIABILITY;
                break;
            case PADriverVideoStreamModeHighReliabilityLowFramerate:
                paMode = ARCOMMANDS_ARDRONE3_MEDIASTREAMING_VIDEOSTREAMMODE_MODE_HIGH_RELIABILITY_LOW_FRAMERATE;
                break;
        }
        
        _deviceController->aRDrone3->sendMediaStreamingVideoStreamMode(_deviceController->aRDrone3, (eARCOMMANDS_ARDRONE3_MEDIASTREAMING_VIDEOSTREAMMODE_MODE)paMode);

    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)settingsPilotingMaxTilt:(float)tilt {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
        _deviceController->aRDrone3->sendPilotingSettingsMaxTilt(_deviceController->aRDrone3, tilt);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)settingsPilotingMaxVerticalSpeed:(float)speed {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
        _deviceController->aRDrone3->sendSpeedSettingsMaxVerticalSpeed(_deviceController->aRDrone3, speed);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)settingsPilotingMaxRotationSpeed:(float)rotation {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
        _deviceController->aRDrone3->sendSpeedSettingsMaxRotationSpeed(_deviceController->aRDrone3, rotation);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)settingsPilotingOutdoor:(BOOL)outdoor {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
        _deviceController->common->sendWifiSettingsOutdoorSetting(_deviceController->common, outdoor ? 1 : 0);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)settingsReturnHomeDelay:(NSUInteger)delay {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
        _deviceController->aRDrone3->sendGPSSettingsReturnHomeDelay(_deviceController->aRDrone3, delay);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)settingsSetCountry:(NSString *)isoCode {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
//        _deviceController->common->sendSettingsCountry(_deviceController->common, (char *)code);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)settingsSetPictureFormat:(PADriverPictureFormat)format {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
        eARCOMMANDS_ARDRONE3_PICTURESETTINGS_PICTUREFORMATSELECTION_TYPE parrotFormat = ARCOMMANDS_ARDRONE3_PICTURESETTINGS_PICTUREFORMATSELECTION_TYPE_RAW;
        
        switch (format) {
            case PADriverPictureFormatRAW:
                parrotFormat = ARCOMMANDS_ARDRONE3_PICTURESETTINGS_PICTUREFORMATSELECTION_TYPE_RAW;
                break;
            case PADriverPictureFormatJPEG:
                parrotFormat = ARCOMMANDS_ARDRONE3_PICTURESETTINGS_PICTUREFORMATSELECTION_TYPE_JPEG;
                break;
            case PADriverPictureFormatSNAPSHOT:
                parrotFormat = ARCOMMANDS_ARDRONE3_PICTURESETTINGS_PICTUREFORMATSELECTION_TYPE_SNAPSHOT;
            default:
                parrotFormat = ARCOMMANDS_ARDRONE3_PICTURESETTINGS_PICTUREFORMATSELECTION_TYPE_RAW;
                break;
        }
        
        _deviceController->aRDrone3->sendPictureSettingsPictureFormatSelection(_deviceController->aRDrone3, (eARCOMMANDS_ARDRONE3_PICTURESETTINGS_PICTUREFORMATSELECTION_TYPE)parrotFormat);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)settingsAutoRecord:(BOOL)autoRecord {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING) && self.massStorageID > 0) {
        _deviceController->aRDrone3->sendPictureSettingsVideoAutorecordSelection(_deviceController->aRDrone3, autoRecord, self.massStorageID);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)settingsTimelapse:(BOOL)enabled interval:(float)interval {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
        _deviceController->aRDrone3->sendPictureSettingsTimelapseSelection(_deviceController->aRDrone3, enabled, interval);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)sendSetPiloting:(BOOL)piloting {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
        _deviceController->common->sendControllerIsPiloting(_deviceController->common, piloting);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)sendGpsPosition:(double)latitude longitude:(double)longitude altitude:(double)altitude horizontalAccuracy:(double)horizontalAccuracy verticalAccuracy:(double)verticalAccuracy {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
        _deviceController->aRDrone3->sendGPSSettingsSendControllerGPS(_deviceController->aRDrone3, latitude, longitude, altitude, horizontalAccuracy, verticalAccuracy);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)settingsReturnHomeType:(PADriverReturnHomeType)type {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
        eARCOMMANDS_ARDRONE3_GPSSETTINGS_HOMETYPE_TYPE paHomeType = (type == PADriverReturnHomeTypeTAKEOFF) ? ARCOMMANDS_ARDRONE3_GPSSETTINGS_HOMETYPE_TYPE_TAKEOFF : ARCOMMANDS_ARDRONE3_GPSSETTINGS_HOMETYPE_TYPE_PILOT;
        _deviceController->aRDrone3->sendGPSSettingsHomeType(_deviceController->aRDrone3, paHomeType);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)hasCamera {
    return YES;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)moveBy:(float)dX dY:(float)dY dZ:(float)dZ rotation:(float)rotation {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
        _deviceController->aRDrone3->sendPilotingMoveBy(_deviceController->aRDrone3, dX, dY, dZ, rotation);
//        The drone will move of the given offsets.
//        Then, event RelativeMoveEnded is triggered.
//        If you send a second relative move command, the drone will trigger a RelativeMoveEnded with the offsets it managed to do before this new command and the value of error set to interrupted.
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)sendPilotingBankedTurn:(BOOL)bankedTurn {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
        _deviceController->aRDrone3->sendPilotingSettingsBankedTurn(_deviceController->aRDrone3, (uint8_t)bankedTurn);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)settingsVideoRecordingMode:(BOOL)bestQuality {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
        eARCOMMANDS_ARDRONE3_PICTURESETTINGS_VIDEORECORDINGMODE_MODE mode = bestQuality ? ARCOMMANDS_ARDRONE3_PICTURESETTINGS_VIDEORECORDINGMODE_MODE_QUALITY : ARCOMMANDS_ARDRONE3_PICTURESETTINGS_VIDEORECORDINGMODE_MODE_TIME;
        
        _deviceController->aRDrone3->sendPictureSettingsVideoRecordingMode(_deviceController->aRDrone3, mode);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)settingsVideoStabilizationMode:(BOOL)roll pitch:(BOOL)pitch {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
        eARCOMMANDS_ARDRONE3_PICTURESETTINGS_VIDEOSTABILIZATIONMODE_MODE mode = ARCOMMANDS_ARDRONE3_PICTURESETTINGS_VIDEOSTABILIZATIONMODE_MODE_NONE;
        
        if (roll && pitch) {
            mode = ARCOMMANDS_ARDRONE3_PICTURESETTINGS_VIDEOSTABILIZATIONMODE_MODE_ROLL_PITCH;
            
        } else if (roll) {
            mode = ARCOMMANDS_ARDRONE3_PICTURESETTINGS_VIDEOSTABILIZATIONMODE_MODE_ROLL;
            
        } else if (pitch) {
            mode = ARCOMMANDS_ARDRONE3_PICTURESETTINGS_VIDEOSTABILIZATIONMODE_MODE_PITCH;
        }
        
        _deviceController->aRDrone3->sendPictureSettingsVideoStabilizationMode(_deviceController->aRDrone3, mode);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)settingsVideoRecordingResolution:(PADriverVideoResolution)resolution {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
        eARCOMMANDS_ARDRONE3_PICTURESETTINGS_VIDEORESOLUTIONS_TYPE type;
        
        switch (resolution) {
            case PADriverVideoResolutionModeBestRecording:
                type = ARCOMMANDS_ARDRONE3_PICTURESETTINGS_VIDEORESOLUTIONS_TYPE_REC1080_STREAM480;
                break;
            case PADriverVideoResolutionModeBestStreaming:
                type = ARCOMMANDS_ARDRONE3_PICTURESETTINGS_VIDEORESOLUTIONS_TYPE_REC720_STREAM720;
                break;
                
            default:
                type = ARCOMMANDS_ARDRONE3_PICTURESETTINGS_VIDEORESOLUTIONS_TYPE_REC1080_STREAM480;
                break;
        }
        
        _deviceController->aRDrone3->sendPictureSettingsVideoResolutions(_deviceController->aRDrone3, type);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)settingsVideoFrameRate:(PADriverVideoFrameRate)frameRate {
    if (_deviceController && (_connectionState == ARCONTROLLER_DEVICE_STATE_RUNNING)) {
        eARCOMMANDS_ARDRONE3_PICTURESETTINGS_VIDEOFRAMERATE_FRAMERATE framerate;
        
        switch (frameRate) {
            case PADriverVideoFrameRate24:
                framerate = ARCOMMANDS_ARDRONE3_PICTURESETTINGS_VIDEOFRAMERATE_FRAMERATE_24_FPS;
                break;
            case PADriverVideoFrameRate25:
                framerate = ARCOMMANDS_ARDRONE3_PICTURESETTINGS_VIDEOFRAMERATE_FRAMERATE_25_FPS;
                break;
            case PADriverVideoFrameRate30:
                framerate = ARCOMMANDS_ARDRONE3_PICTURESETTINGS_VIDEOFRAMERATE_FRAMERATE_30_FPS;
                break;
                
            default:
                framerate = ARCOMMANDS_ARDRONE3_PICTURESETTINGS_VIDEOFRAMERATE_FRAMERATE_24_FPS;
                break;
        }
        
        _deviceController->aRDrone3->sendPictureSettingsVideoFramerate(_deviceController->aRDrone3, framerate);
    }
}


////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Device controller callbacks

// called when the state of the device controller has changed
static void stateChanged (eARCONTROLLER_DEVICE_STATE newState, eARCONTROLLER_ERROR error, void *customData) {
    PABeebopDriver *bebopDrone = (__bridge PABeebopDriver*)customData;
    if (bebopDrone != nil) {
        switch (newState) {
            case ARCONTROLLER_DEVICE_STATE_RUNNING:
                bebopDrone.deviceController->aRDrone3->sendMediaStreamingVideoEnable(bebopDrone.deviceController->aRDrone3, 1);
                break;
            case ARCONTROLLER_DEVICE_STATE_STOPPED:
                break;
            default:
                break;
        }
        bebopDrone.connectionState = [PABeebopDriver convertDeviceParrotState:newState];
        [bebopDrone.delegate paDriver:bebopDrone connectionDidChange:[PABeebopDriver convertDeviceParrotState:newState]];
//        dispatch_async(dispatch_get_main_queue(), ^{
//            bebopDrone.connectionState = [PABeebopDriver convertDeviceParrotState:newState];
//            [bebopDrone.delegate paDriver:bebopDrone connectionDidChange:[PABeebopDriver convertDeviceParrotState:newState]];
//        });
    }
}

void batteryStateChanged(ARCONTROLLER_DICTIONARY_ELEMENT_t *elementDictionary, PABeebopDriver *bebopDrone) {
    ARCONTROLLER_DICTIONARY_ARG_t *arg = NULL;
    ARCONTROLLER_DICTIONARY_ELEMENT_t *element = NULL;
    
    HASH_FIND_STR (elementDictionary, ARCONTROLLER_DICTIONARY_SINGLE_KEY, element);
    if (element != NULL) {
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_COMMON_COMMONSTATE_BATTERYSTATECHANGED_PERCENT, arg);
        if (arg != NULL) {
            uint8_t battery = arg->value.U8;
            [bebopDrone.delegate paDriver:bebopDrone batteryDidChange:battery];
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [bebopDrone.delegate paDriver:bebopDrone batteryDidChange:battery];
//            });
        }
    }
}

void flyingStateChanged(ARCONTROLLER_DICTIONARY_ELEMENT_t *elementDictionary, PABeebopDriver *bebopDrone) {
    ARCONTROLLER_DICTIONARY_ARG_t *arg = NULL;
    ARCONTROLLER_DICTIONARY_ELEMENT_t *element = NULL;
    
    HASH_FIND_STR (elementDictionary, ARCONTROLLER_DICTIONARY_SINGLE_KEY, element);
    if (element != NULL) {
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_PILOTINGSTATE_FLYINGSTATECHANGED_STATE, arg);
        if (arg != NULL) {
            bebopDrone.flyingState = [PABeebopDriver convertFlyingParrotState:arg->value.I32];
            [bebopDrone.delegate paDriver:bebopDrone flyingStateDidChange:bebopDrone.flyingState];
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [bebopDrone.delegate paDriver:bebopDrone flyingStateDidChange:bebopDrone.flyingState];
//            });
        }
    }
}

void rundIDChanged(ARCONTROLLER_DICTIONARY_ELEMENT_t *elementDictionary, PABeebopDriver *bebopDrone) {
    ARCONTROLLER_DICTIONARY_ARG_t *arg = NULL;
    ARCONTROLLER_DICTIONARY_ELEMENT_t *element = NULL;
    
    HASH_FIND_STR (elementDictionary, ARCONTROLLER_DICTIONARY_SINGLE_KEY, element);
    if (element != NULL) {
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_COMMON_RUNSTATE_RUNIDCHANGED_RUNID, arg);
        if (arg != NULL) {
            char * runId = arg->value.String;
            if (runId != NULL) {
                bebopDrone.currentRunId = [NSString stringWithUTF8String:runId];
            }
        }
    }
}

//Drone position changed
//
//latitude (double): Latitude position in decimal degrees (500.0 if not available)
//longitude (double): Longitude position in decimal degrees (500.0 if not available)
//altitude (double): Altitude in meters (from GPS)
//Triggered regularly when the drone flies (if its gps has fixed).
void dronePositionChanged(ARCONTROLLER_DICTIONARY_ELEMENT_t *elementDictionary, PABeebopDriver *bebopDrone) {
    ARCONTROLLER_DICTIONARY_ARG_t *arg = NULL;
    ARCONTROLLER_DICTIONARY_ELEMENT_t *element = NULL;
    HASH_FIND_STR (elementDictionary, ARCONTROLLER_DICTIONARY_SINGLE_KEY, element);
    if (element != NULL) {
        double latitude = 0;
        double longitude = 0;
        double altitude = 0;
        
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_PILOTINGSTATE_GPSLOCATIONCHANGED_LATITUDE, arg);
        if (arg != NULL) {
            latitude = arg->value.Double;
        }
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_PILOTINGSTATE_GPSLOCATIONCHANGED_LONGITUDE, arg);
        if (arg != NULL) {
            longitude = arg->value.Double;
        }
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_PILOTINGSTATE_GPSLOCATIONCHANGED_ALTITUDE, arg);
        if (arg != NULL) {
            altitude = arg->value.Double;
        }
        
        [bebopDrone.delegate paDriver:bebopDrone positionDidChangeWithLatitude:latitude longitude:longitude altitude:altitude];
    }
}

//Max Altitude changed.
//
//current (float): Current altitude max
//min (float): Range min of altitude
//max (float): Range max of altitude
void maxAltitudeChanged(ARCONTROLLER_DICTIONARY_ELEMENT_t *elementDictionary, PABeebopDriver *bebopDrone) {
    ARCONTROLLER_DICTIONARY_ARG_t *arg = NULL;
    ARCONTROLLER_DICTIONARY_ELEMENT_t *element = NULL;
    HASH_FIND_STR (elementDictionary, ARCONTROLLER_DICTIONARY_SINGLE_KEY, element);
    if (element != NULL) {
        float current = 0;
        float min = 0;
        float max = 0;
        
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_PILOTINGSETTINGSSTATE_MAXALTITUDECHANGED_CURRENT, arg);
        if (arg != NULL) {
            current = arg->value.Float;
        }
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_PILOTINGSETTINGSSTATE_MAXALTITUDECHANGED_MIN, arg);
        if (arg != NULL) {
            min = arg->value.Float;
        }
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_PILOTINGSETTINGSSTATE_MAXALTITUDECHANGED_MAX, arg);
        if (arg != NULL) {
            max = arg->value.Float;
        }
        
        [bebopDrone.delegate paDriver:bebopDrone maxAltitudeDidChange:current min:min max:max];
    }
}

//Max tilt changed.
//
//current (float): Current max tilt
//min (float): Range min of tilt
//max (float): Range max of tilt
void maxTiltChanged(ARCONTROLLER_DICTIONARY_ELEMENT_t *elementDictionary, PABeebopDriver *bebopDrone) {
    ARCONTROLLER_DICTIONARY_ARG_t *arg = NULL;
    ARCONTROLLER_DICTIONARY_ELEMENT_t *element = NULL;
    HASH_FIND_STR (elementDictionary, ARCONTROLLER_DICTIONARY_SINGLE_KEY, element);
    if (element != NULL) {
        float current = 0;
        float min = 0;
        float max = 0;
        
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_PILOTINGSETTINGSSTATE_MAXTILTCHANGED_CURRENT, arg);
        if (arg != NULL) {
            current = arg->value.Float;
        }
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_PILOTINGSETTINGSSTATE_MAXTILTCHANGED_MIN, arg);
        if (arg != NULL) {
            min = arg->value.Float;
        }
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_PILOTINGSETTINGSSTATE_MAXTILTCHANGED_MAX, arg);
        if (arg != NULL) {
            max = arg->value.Float;
        }
        
        [bebopDrone.delegate paDriver:bebopDrone maxTiltDidChange:current min:min max:max];
    }
}

//Max distance sent by the drone
//
//current (float): Current max distance in meter
//min (float): Minimal possible max distance
//max (float): Maximal possible max distance
void maxDistanceChanged(ARCONTROLLER_DICTIONARY_ELEMENT_t *elementDictionary, PABeebopDriver *bebopDrone) {
    ARCONTROLLER_DICTIONARY_ARG_t *arg = NULL;
    ARCONTROLLER_DICTIONARY_ELEMENT_t *element = NULL;
    HASH_FIND_STR (elementDictionary, ARCONTROLLER_DICTIONARY_SINGLE_KEY, element);
    if (element != NULL) {
        float current = 0;
        float min = 0;
        float max = 0;
        
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_PILOTINGSETTINGSSTATE_MAXDISTANCECHANGED_CURRENT, arg);
        if (arg != NULL) {
            current = arg->value.Float;
        }
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_PILOTINGSETTINGSSTATE_MAXDISTANCECHANGED_MIN, arg);
        if (arg != NULL) {
            min = arg->value.Float;
        }
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_PILOTINGSETTINGSSTATE_MAXDISTANCECHANGED_MAX, arg);
        if (arg != NULL) {
            max = arg->value.Float;
        }
        
        [bebopDrone.delegate paDriver:bebopDrone maxDistanceDidChange:current min:min max:max];
    }
}

//Drone altitude changed
//
//altitude (double): Altitude in meters
void altitudeChanged(ARCONTROLLER_DICTIONARY_ELEMENT_t *elementDictionary, PABeebopDriver *bebopDrone) {
    ARCONTROLLER_DICTIONARY_ARG_t *arg = NULL;
    ARCONTROLLER_DICTIONARY_ELEMENT_t *element = NULL;
    HASH_FIND_STR (elementDictionary, ARCONTROLLER_DICTIONARY_SINGLE_KEY, element);
    if (element != NULL) {
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_PILOTINGSTATE_ALTITUDECHANGED_ALTITUDE, arg);
        if (arg != NULL) {
            double altitude = arg->value.Double;
            [bebopDrone.delegate paDriver:bebopDrone altitudeDidChange:altitude];
        }
    }
}

//Drone speed changed in the North East Down coordinates.
//
//speedX (float): Speed on the x axis (when drone moves forward, speed is > 0) (in m/s)
//speedY (float): Speed on the y axis (when drone moves to right, speed is > 0) (in m/s)
//speedZ (float): Speed on the z axis (when drone moves down, speed is > 0) (in m/s)
void speedChanged(ARCONTROLLER_DICTIONARY_ELEMENT_t *elementDictionary, PABeebopDriver *bebopDrone) {
    ARCONTROLLER_DICTIONARY_ARG_t *arg = NULL;
    ARCONTROLLER_DICTIONARY_ELEMENT_t *element = NULL;
    HASH_FIND_STR (elementDictionary, ARCONTROLLER_DICTIONARY_SINGLE_KEY, element);
    if (element != NULL) {
        float speedX = 0;
        float speedY = 0;
        float speedZ = 0;
        
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_PILOTINGSTATE_SPEEDCHANGED_SPEEDX, arg);
        if (arg != NULL) {
            speedX = arg->value.Float;
        }
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_PILOTINGSTATE_SPEEDCHANGED_SPEEDY, arg);
        if (arg != NULL) {
            speedY = arg->value.Float;
        }
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_PILOTINGSTATE_SPEEDCHANGED_SPEEDZ, arg);
        if (arg != NULL) {
            speedZ = arg->value.Float;
        }
        
        [bebopDrone.delegate paDriver:bebopDrone speedDidChangeWithSpeedX:speedX speedY:speedY speedZ:speedZ];
    }
}

//Motor status changed
//
//motorIds (u8): Bit field for concerned motor. If bit 0 = 1, motor 1 is affected by this error. Same with bit 1, 2 and 3.
//motorError (enum): Enumeration of the motor error
//noError: No error detected
//errorEEPRom: EEPROM access failure
//errorMotorStalled: Motor stalled
//errorPropellerSecurity: Propeller cutout security triggered
//errorCommLost: Communication with motor failed by timeout
//errorRCEmergencyStop: RC emergency stop
//errorRealTime: Motor controler scheduler real-time out of bounds
//errorMotorSetting: One or several incorrect values in motor settings
//errorTemperature: Too hot or too cold Cypress temperature
//errorBatteryVoltage: Battery voltage out of bounds
//errorLipoCells: Incorrect number of LIPO cells
//errorMOSFET: Defectuous MOSFET or broken motor phases
//errorBootloader: Not use for BLDC but useful for HAL
//errorAssert: Error Made by BLDC_ASSERT()
//Triggered when an error on motors happens.
void motorStatusChanged(ARCONTROLLER_DICTIONARY_ELEMENT_t *elementDictionary, PABeebopDriver *bebopDrone) {
    ARCONTROLLER_DICTIONARY_ARG_t *arg = NULL;
    ARCONTROLLER_DICTIONARY_ELEMENT_t *element = NULL;
    HASH_FIND_STR (elementDictionary, ARCONTROLLER_DICTIONARY_SINGLE_KEY, element);
    if (element != NULL)
        {
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_SETTINGSSTATE_MOTORERRORSTATECHANGED_MOTORIDS, arg);
        if (arg != NULL)
            {
            uint8_t motorIds = arg->value.U8;
            }
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_SETTINGSSTATE_MOTORERRORSTATECHANGED_MOTORERROR, arg);
        if (arg != NULL)
            {
            eARCOMMANDS_ARDRONE3_SETTINGSSTATE_MOTORERRORSTATECHANGED_MOTORERROR motorError = arg->value.I32;
            }
        }
}

//Motor status about last error
//
//motorError (enum): Enumeration of the motor error
//noError: No error detected
//errorEEPRom: EEPROM access failure
//errorMotorStalled: Motor stalled
//errorPropellerSecurity: Propeller cutout security triggered
//errorCommLost: Communication with motor failed by timeout
//errorRCEmergencyStop: RC emergency stop
//errorRealTime: Motor controler scheduler real-time out of bounds
//errorMotorSetting: One or several incorrect values in motor settings
//errorBatteryVoltage: Battery voltage out of bounds
//errorLipoCells: Incorrect number of LIPO cells
//errorMOSFET: Defectuous MOSFET or broken motor phases
//errorTemperature: Too hot or too cold Cypress temperature
//errorBootloader: Not use for BLDC but useful for HAL
//errorAssert: Error Made by BLDC_ASSERT()
//Triggered after an error occured.
void motorStatusLastErrorChanged(ARCONTROLLER_DICTIONARY_ELEMENT_t *elementDictionary, PABeebopDriver *bebopDrone) {
    ARCONTROLLER_DICTIONARY_ARG_t *arg = NULL;
    ARCONTROLLER_DICTIONARY_ELEMENT_t *element = NULL;
    HASH_FIND_STR (elementDictionary, ARCONTROLLER_DICTIONARY_SINGLE_KEY, element);
    if (element != NULL)
        {
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_SETTINGSSTATE_MOTORERRORLASTERRORCHANGED_MOTORERROR, arg);
        if (arg != NULL)
            {
            eARCOMMANDS_ARDRONE3_SETTINGSSTATE_MOTORERRORLASTERRORCHANGED_MOTORERROR motorError = arg->value.I32;
            }
        }
}

//Orientation of the camera center.
//
//This is the value to send when we want to center the camera.
//
//tilt (i8): Tilt value (in degree)
//pan (i8): Pan value (in degree)
//Triggered at the connection.
void cameraCenterOrientationCommand(ARCONTROLLER_DICTIONARY_ELEMENT_t *elementDictionary, PABeebopDriver *bebopDrone) {
    ARCONTROLLER_DICTIONARY_ARG_t *arg = NULL;
    ARCONTROLLER_DICTIONARY_ELEMENT_t *element = NULL;
    HASH_FIND_STR (elementDictionary, ARCONTROLLER_DICTIONARY_SINGLE_KEY, element);
    if (element != NULL) {
        NSInteger tilt = 0;
        NSInteger pan = 0;
        
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_CAMERASTATE_DEFAULTCAMERAORIENTATION_TILT, arg);
        if (arg != NULL) {
            tilt = arg->value.I8;
        }
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_CAMERASTATE_DEFAULTCAMERAORIENTATION_PAN, arg);
        if (arg != NULL) {
            pan = arg->value.I8;
        }
        
        [bebopDrone.delegate paDriver:bebopDrone cameraCenterOrientationTilt:tilt pan:pan];
    }
}

//The number of gps sattelites seen changed.
//
//numberOfSatellite (u8): The number of satellite
//Triggered when the number of satellites seen changes.
//
//Supported by
//
//Bebop 2
void gpsSattelitesNumberChanged(ARCONTROLLER_DICTIONARY_ELEMENT_t *elementDictionary, PABeebopDriver *bebopDrone) {
    ARCONTROLLER_DICTIONARY_ARG_t *arg = NULL;
    ARCONTROLLER_DICTIONARY_ELEMENT_t *element = NULL;
    HASH_FIND_STR (elementDictionary, ARCONTROLLER_DICTIONARY_SINGLE_KEY, element);
    if (element != NULL) {
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_GPSSTATE_NUMBEROFSATELLITECHANGED_NUMBEROFSATELLITE, arg);
        if (arg != NULL) {
            uint8_t numberOfSatellite = arg->value.U8;
            [bebopDrone.delegate paDriver:bebopDrone gpsSattelitesNumberDidChange:numberOfSatellite];
        }
    }
}

//Event of picture recording
//
//event (enum): Last event of picture recording
//taken: Picture taken and saved
//failed: Picture failed
//error (enum): Error to explain the event
//ok: No Error
//unknown: Unknown generic error ; only when state is failed
//busy: Picture recording is busy ; only when state is failed
//notAvailable: Picture recording not available ; only when state is failed
//memoryFull: Memory full ; only when state is failed
//lowBattery: Battery is too low to record.
//Triggered by TakePicture.
//
//This event is a notification, you can’t retrieve it in the cache of the device controller.
void pictureEventChanged(ARCONTROLLER_DICTIONARY_ELEMENT_t *elementDictionary, PABeebopDriver *bebopDrone) {
    ARCONTROLLER_DICTIONARY_ARG_t *arg = NULL;
    ARCONTROLLER_DICTIONARY_ELEMENT_t *element = NULL;
    HASH_FIND_STR (elementDictionary, ARCONTROLLER_DICTIONARY_SINGLE_KEY, element);
    if (element != NULL) {
        PADriverPictureRecordingEvent event;
        PADriverPictureRecordingStatus status = PADriverPictureRecordingStatusUnknown;
        
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_MEDIARECORDEVENT_PICTUREEVENTCHANGED_EVENT, arg);
        if (arg != NULL) {
            eARCOMMANDS_ARDRONE3_MEDIARECORDEVENT_PICTUREEVENTCHANGED_EVENT event = arg->value.I32;
//            d
        }
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_MEDIARECORDEVENT_PICTUREEVENTCHANGED_ERROR, arg);
        if (arg != NULL) {
            eARCOMMANDS_ARDRONE3_MEDIARECORDEVENT_PICTUREEVENTCHANGED_ERROR error = arg->value.I32;
        }
        
//        PADriverVideoRecordingEvent event = PADriverVideoRecordingEventStop;
//        PADriverVideoRecordingStatus status = PADriverVideoRecordingStatusUnknown;
//        
//        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_MEDIARECORDEVENT_VIDEOEVENTCHANGED_EVENT, arg);
//        if (arg != NULL) {
//            event = [PABeebopDriver convertVideoRecordingParrotEvent:arg->value.I32];
//        }
//        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_MEDIARECORDEVENT_VIDEOEVENTCHANGED_ERROR, arg);
//        if (arg != NULL) {
//            status = [PABeebopDriver convertVideoRecordingParrotStatus:arg->value.I32];
//        }
//        
//        [bebopDrone.delegate paDriver:bebopDrone videoRecordingDidChange:event status:status];
        
//        [bebopDrone.delegate paDriver:bebopDrone pictureRecordingDidChange:event status:status];
    }
}

//Event of video recording
//
//event (enum): Event of video recording
//start: Video start
//stop: Video stop and saved
//failed: Video failed
//error (enum): Error to explain the event
//ok: No Error
//unknown: Unknown generic error ; only when state is failed
//busy: Video recording is busy ; only when state is failed
//notAvailable: Video recording not available ; only when state is failed
//memoryFull: Memory full
//lowBattery: Battery is too low to record.
//autoStopped: Video was auto stopped
//Triggered by VideoRecord or by a change in the video state.
//
//This event is a notification, you can’t retrieve it in the cache of the device controller.
void videoEventChanged(ARCONTROLLER_DICTIONARY_ELEMENT_t *elementDictionary, PABeebopDriver *bebopDrone) {
    ARCONTROLLER_DICTIONARY_ARG_t *arg = NULL;
    ARCONTROLLER_DICTIONARY_ELEMENT_t *element = NULL;
    HASH_FIND_STR (elementDictionary, ARCONTROLLER_DICTIONARY_SINGLE_KEY, element);
    if (element != NULL) {
        PADriverVideoRecordingEvent event = PADriverVideoRecordingEventStop;
        PADriverVideoRecordingStatus status = PADriverVideoRecordingStatusUnknown;
        
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_MEDIARECORDEVENT_VIDEOEVENTCHANGED_EVENT, arg);
        if (arg != NULL) {
            event = [PABeebopDriver convertVideoRecordingParrotEvent:arg->value.I32];
        }
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_MEDIARECORDEVENT_VIDEOEVENTCHANGED_ERROR, arg);
        if (arg != NULL) {
            status = [PABeebopDriver convertVideoRecordingParrotStatus:arg->value.I32];
        }
        
        [bebopDrone.delegate paDriver:bebopDrone videoRecordingDidChange:event status:status];
    }
}

//Drone alert state changed
//
//state (enum): Drone alert state
//none: No alert
//user: User emergency alert
//cut_out: Cut out alert
//critical_battery: Critical battery alert
//low_battery: Low battery alert
//too_much_angle: The angle of the drone is too high
//Triggered when an alert happens on the drone.
void droneAlertChanged(ARCONTROLLER_DICTIONARY_ELEMENT_t *elementDictionary, PABeebopDriver *bebopDrone) {
    ARCONTROLLER_DICTIONARY_ARG_t *arg = NULL;
    ARCONTROLLER_DICTIONARY_ELEMENT_t *element = NULL;
    HASH_FIND_STR (elementDictionary, ARCONTROLLER_DICTIONARY_SINGLE_KEY, element);
    if (element != NULL) {
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_PILOTINGSTATE_ALERTSTATECHANGED_STATE, arg);
        if (arg != NULL) {
            eARCOMMANDS_ARDRONE3_PILOTINGSTATE_ALERTSTATECHANGED_STATE state = arg->value.I32;
        }
    }
}

//Status of the camera settings
//
//fov (float): Value of the camera horizontal fov (in degree)
//panMax (float): Value of max pan (right pan) (in degree)
//panMin (float): Value of min pan (left pan) (in degree)
//tiltMax (float): Value of max tilt (top tilt) (in degree)
//tiltMin (float): Value of min tilt (bottom tilt) (in degree)
//Triggered at connection.
void cameraSettingsChanged(ARCONTROLLER_DICTIONARY_ELEMENT_t *elementDictionary, PABeebopDriver *bebopDrone) {
    ARCONTROLLER_DICTIONARY_ARG_t *arg = NULL;
    ARCONTROLLER_DICTIONARY_ELEMENT_t *element = NULL;
    HASH_FIND_STR (elementDictionary, ARCONTROLLER_DICTIONARY_SINGLE_KEY, element);
    if (element != NULL) {
        float fov = 0;
        float panMax = 0;
        float panMin = 0;
        float tiltMax = 0;
        float tiltMin = 0;
        
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_COMMON_CAMERASETTINGSSTATE_CAMERASETTINGSCHANGED_FOV, arg);
        if (arg != NULL) {
            fov = arg->value.Float;
        }
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_COMMON_CAMERASETTINGSSTATE_CAMERASETTINGSCHANGED_PANMAX, arg);
        if (arg != NULL) {
            panMax = arg->value.Float;
        }
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_COMMON_CAMERASETTINGSSTATE_CAMERASETTINGSCHANGED_PANMIN, arg);
        if (arg != NULL) {
            panMin = arg->value.Float;
        }
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_COMMON_CAMERASETTINGSSTATE_CAMERASETTINGSCHANGED_TILTMAX, arg);
        if (arg != NULL) {
            tiltMax = arg->value.Float;
        }
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_COMMON_CAMERASETTINGSSTATE_CAMERASETTINGSCHANGED_TILTMIN, arg);
        if (arg != NULL) {
            tiltMin = arg->value.Float;
        }
        
        [bebopDrone.delegate paDriver:bebopDrone cameraSettingsDidChange:fov maxPan:panMax minPan:panMin maxTilt:tiltMax minTilt:tiltMin];
    }
}

//Max vertical speed changed.
//
//current (float): Current max vertical speed in m/s
//min (float): Range min of vertical speed
//max (float): Range max of vertical speed
//Triggered by SetMaxVerticalSpeed.
void maxVerticalSpeedChanged(ARCONTROLLER_DICTIONARY_ELEMENT_t *elementDictionary, PABeebopDriver *bebopDrone) {
    ARCONTROLLER_DICTIONARY_ARG_t *arg = NULL;
    ARCONTROLLER_DICTIONARY_ELEMENT_t *element = NULL;
    HASH_FIND_STR (elementDictionary, ARCONTROLLER_DICTIONARY_SINGLE_KEY, element);
    if (element != NULL) {
        float current = 0;
        float min = 0;
        float max = 0;
        
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_SPEEDSETTINGSSTATE_MAXVERTICALSPEEDCHANGED_CURRENT, arg);
        if (arg != NULL) {
            current = arg->value.Float;
        }
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_SPEEDSETTINGSSTATE_MAXVERTICALSPEEDCHANGED_MIN, arg);
        if (arg != NULL) {
            min = arg->value.Float;
        }
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_SPEEDSETTINGSSTATE_MAXVERTICALSPEEDCHANGED_MAX, arg);
        if (arg != NULL) {
            max = arg->value.Float;
        }
        
        [bebopDrone.delegate paDriver:bebopDrone maxVerticalSpeedDidChange:current min:min max:max];
    }
}

//Max rotation speed changed.
//
//current (float): Current max rotation speed in degree/s
//min (float): Range min of rotation speed
//max (float): Range max of rotation speed
//Triggered by SetMaxRotationSpeed.
void maxRotationSpeedChanged(ARCONTROLLER_DICTIONARY_ELEMENT_t *elementDictionary, PABeebopDriver *bebopDrone) {
    ARCONTROLLER_DICTIONARY_ARG_t *arg = NULL;
    ARCONTROLLER_DICTIONARY_ELEMENT_t *element = NULL;
    HASH_FIND_STR (elementDictionary, ARCONTROLLER_DICTIONARY_SINGLE_KEY, element);
    if (element != NULL) {
        float current = 0;
        float min = 0;
        float max = 0;
        
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_SPEEDSETTINGSSTATE_MAXROTATIONSPEEDCHANGED_CURRENT, arg);
        if (arg != NULL) {
            current = arg->value.Float;
        }
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_SPEEDSETTINGSSTATE_MAXROTATIONSPEEDCHANGED_MIN, arg);
        if (arg != NULL) {
            min = arg->value.Float;
        }
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_SPEEDSETTINGSSTATE_MAXROTATIONSPEEDCHANGED_MAX, arg);
        if (arg != NULL) {
            max = arg->value.Float;
        }
        
        [bebopDrone.delegate paDriver:bebopDrone maxRotationSpeedDidChange:current min:min max:max];
    }
}

void pictureFormatChanged(ARCONTROLLER_DICTIONARY_ELEMENT_t *elementDictionary, PABeebopDriver *bebopDrone) {
    ARCONTROLLER_DICTIONARY_ARG_t *arg = NULL;
    ARCONTROLLER_DICTIONARY_ELEMENT_t *element = NULL;
    HASH_FIND_STR (elementDictionary, ARCONTROLLER_DICTIONARY_SINGLE_KEY, element);
    if (element != NULL) {
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_PICTURESETTINGSSTATE_PICTUREFORMATCHANGED_TYPE, arg);
        if (arg != NULL) {
            eARCOMMANDS_ARDRONE3_PICTURESETTINGSSTATE_PICTUREFORMATCHANGED_TYPE type = arg->value.I32;
        }
        
        PADriverPictureFormat format = PADriverPictureFormatRAW;
        
        switch (format) {
            case ARCOMMANDS_ARDRONE3_PICTURESETTINGS_PICTUREFORMATSELECTION_TYPE_RAW:
                format = PADriverPictureFormatRAW;
                break;
            case ARCOMMANDS_ARDRONE3_PICTURESETTINGS_PICTUREFORMATSELECTION_TYPE_JPEG:
                format = PADriverPictureFormatJPEG;
                break;
            case ARCOMMANDS_ARDRONE3_PICTURESETTINGS_PICTUREFORMATSELECTION_TYPE_SNAPSHOT:
                format = PADriverPictureFormatSNAPSHOT;
            default:
                format = PADriverPictureFormatRAW;
                break;
        }
        
        [bebopDrone.delegate paDriver:bebopDrone pictureFormatDidChange:format];
    }
}

void massStorageListChanged(ARCONTROLLER_DICTIONARY_ELEMENT_t *elementDictionary, PABeebopDriver *bebopDrone) {
    ARCONTROLLER_DICTIONARY_ARG_t *arg = NULL;
    ARCONTROLLER_DICTIONARY_ELEMENT_t *dictElement = NULL;
    ARCONTROLLER_DICTIONARY_ELEMENT_t *dictTmp = NULL;
    HASH_ITER(hh, elementDictionary, dictElement, dictTmp)
    {
    HASH_FIND_STR (dictElement->arguments, ARCONTROLLER_DICTIONARY_KEY_COMMON_COMMONSTATE_MASSSTORAGESTATELISTCHANGED_MASS_STORAGE_ID, arg);
    if (arg != NULL)
        {
        uint8_t mass_storage_id = arg->value.U8;
        bebopDrone.massStorageID = mass_storage_id;
        }
    HASH_FIND_STR (dictElement->arguments, ARCONTROLLER_DICTIONARY_KEY_COMMON_COMMONSTATE_MASSSTORAGESTATELISTCHANGED_NAME, arg);
    if (arg != NULL)
        {
        char * name = arg->value.String;
        }
    }
}

void gpsStateChanged(ARCONTROLLER_DICTIONARY_ELEMENT_t *elementDictionary, PABeebopDriver *bebopDrone) {
    ARCONTROLLER_DICTIONARY_ARG_t *arg = NULL;
    ARCONTROLLER_DICTIONARY_ELEMENT_t *element = NULL;
    HASH_FIND_STR (elementDictionary, ARCONTROLLER_DICTIONARY_SINGLE_KEY, element);
    if (element != NULL)
        {
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_GPSSETTINGSSTATE_GPSFIXSTATECHANGED_FIXED, arg);
        if (arg != NULL)
            {
            uint8_t fixed = arg->value.U8;
            [bebopDrone.delegate paDriver:bebopDrone gpsStatusDidChanged:fixed];
            }
        }
}

void returnHomeStateChanged(ARCONTROLLER_DICTIONARY_ELEMENT_t *elementDictionary, PABeebopDriver *bebopDrone) {
    ARCONTROLLER_DICTIONARY_ARG_t *arg = NULL;
    ARCONTROLLER_DICTIONARY_ELEMENT_t *element = NULL;
    HASH_FIND_STR (elementDictionary, ARCONTROLLER_DICTIONARY_SINGLE_KEY, element);
    if (element != NULL)
        {
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_PILOTINGSTATE_NAVIGATEHOMESTATECHANGED_STATE, arg);
        if (arg != NULL)
            {
            PADriverReturnHomeState state = [PABeebopDriver convertReturnHomeParrotState:arg->value.I32];
            [bebopDrone.delegate paDriver:bebopDrone returnHomeStateChanged:state];
            }
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_PILOTINGSTATE_NAVIGATEHOMESTATECHANGED_REASON, arg);
        if (arg != NULL)
            {
//            eARCOMMANDS_ARDRONE3_PILOTINGSTATE_NAVIGATEHOMESTATECHANGED_REASON reason = arg->value.I32;
            }
        }
    
//    typedef enum {
//        PADriverReturnHomeStateAvailable = 0,
//        PADriverReturnHomeStateInProgress,
//        PADriverReturnHomeStateUnavailable,
//        PADriverReturnHomeStatePending
//    } PADriverReturnHomeState;
    
    //    ARCOMMANDS_ARDRONE3_PILOTINGSTATE_NAVIGATEHOMESTATECHANGED_STATE_AVAILABLE = 0,    ///< Navigate home is available
    //    ARCOMMANDS_ARDRONE3_PILOTINGSTATE_NAVIGATEHOMESTATECHANGED_STATE_INPROGRESS = 1,    ///< Navigate home is in progress
    //    ARCOMMANDS_ARDRONE3_PILOTINGSTATE_NAVIGATEHOMESTATECHANGED_STATE_UNAVAILABLE = 2,    ///< Navigate home is not available
    //    ARCOMMANDS_ARDRONE3_PILOTINGSTATE_NAVIGATEHOMESTATECHANGED_STATE_PENDING = 3,    ///< Navigate home has been received, but its process is pending
    //    ARCOMMANDS_ARDRONE3_PILOTINGSTATE_NAVIGATEHOMESTATECHANGED_STATE_MAX
    //} eARCOMMANDS_ARDRONE3_PILOTINGSTATE_NAVIGATEHOMESTATECHANGED_STATE;
    
//    ARCOMMANDS_ARDRONE3_PILOTINGSTATE_NAVIGATEHOMESTATECHANGED_STATE_AVAILABLE = 0,    ///< Navigate home is available
//    ARCOMMANDS_ARDRONE3_PILOTINGSTATE_NAVIGATEHOMESTATECHANGED_STATE_INPROGRESS = 1,    ///< Navigate home is in progress
//    ARCOMMANDS_ARDRONE3_PILOTINGSTATE_NAVIGATEHOMESTATECHANGED_STATE_UNAVAILABLE = 2,    ///< Navigate home is not available
//    ARCOMMANDS_ARDRONE3_PILOTINGSTATE_NAVIGATEHOMESTATECHANGED_STATE_PENDING = 3,    ///< Navigate home has been received, but its process is pending
//    ARCOMMANDS_ARDRONE3_PILOTINGSTATE_NAVIGATEHOMESTATECHANGED_STATE_MAX
//} eARCOMMANDS_ARDRONE3_PILOTINGSTATE_NAVIGATEHOMESTATECHANGED_STATE;
    
//    typedef enum
//    {
//    ARCOMMANDS_ARDRONE3_PILOTINGSTATE_NAVIGATEHOMESTATECHANGED_REASON_USERREQUEST = 0,    ///< User requested a navigate home (available->inProgress)
//    ARCOMMANDS_ARDRONE3_PILOTINGSTATE_NAVIGATEHOMESTATECHANGED_REASON_CONNECTIONLOST = 1,    ///< Connection between controller and product lost (available->inProgress)
//    ARCOMMANDS_ARDRONE3_PILOTINGSTATE_NAVIGATEHOMESTATECHANGED_REASON_LOWBATTERY = 2,    ///< Low battery occurred (available->inProgress)
//    ARCOMMANDS_ARDRONE3_PILOTINGSTATE_NAVIGATEHOMESTATECHANGED_REASON_FINISHED = 3,    ///< Navigate home is finished (inProgress->available)
//    ARCOMMANDS_ARDRONE3_PILOTINGSTATE_NAVIGATEHOMESTATECHANGED_REASON_STOPPED = 4,    ///< Navigate home has been stopped (inProgress->available)
//    ARCOMMANDS_ARDRONE3_PILOTINGSTATE_NAVIGATEHOMESTATECHANGED_REASON_DISABLED = 5,    ///< Navigate home disabled by product (inProgress->unavailable or available->unavailable)
//    ARCOMMANDS_ARDRONE3_PILOTINGSTATE_NAVIGATEHOMESTATECHANGED_REASON_ENABLED = 6,    ///< Navigate home enabled by product (unavailable->available)
//    ARCOMMANDS_ARDRONE3_PILOTINGSTATE_NAVIGATEHOMESTATECHANGED_REASON_MAX
//    } eARCOMMANDS_ARDRONE3_PILOTINGSTATE_NAVIGATEHOMESTATECHANGED_REASON;
}

void calibrationState(ARCONTROLLER_DICTIONARY_ELEMENT_t *elementDictionary, PABeebopDriver *bebopDrone) {
    ARCONTROLLER_DICTIONARY_ARG_t *arg = NULL;
    ARCONTROLLER_DICTIONARY_ELEMENT_t *element = NULL;
    HASH_FIND_STR (elementDictionary, ARCONTROLLER_DICTIONARY_SINGLE_KEY, element);
    if (element != NULL) {
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_COMMON_CALIBRATIONSTATE_MAGNETOCALIBRATIONREQUIREDSTATE_REQUIRED, arg);
        if (arg != NULL) {
            uint8_t required = arg->value.U8;
            [bebopDrone.delegate paDriver:bebopDrone calibrationState:required];
        }
    }
}

void bankedTurnChanged(ARCONTROLLER_DICTIONARY_ELEMENT_t *elementDictionary, PABeebopDriver *bebopDrone) {
    ARCONTROLLER_DICTIONARY_ARG_t *arg = NULL;
    ARCONTROLLER_DICTIONARY_ELEMENT_t *element = NULL;
    HASH_FIND_STR (elementDictionary, ARCONTROLLER_DICTIONARY_SINGLE_KEY, element);
    if (element != NULL)
        {
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_PILOTINGSETTINGSSTATE_BANKEDTURNCHANGED_STATE, arg);
        if (arg != NULL)
            {
            uint8_t state = arg->value.U8;
            [bebopDrone.delegate paDriver:bebopDrone bankedTurnDidChange:state];
        }
    }
}

void returnHomeDelayChanged(ARCONTROLLER_DICTIONARY_ELEMENT_t *elementDictionary, PABeebopDriver *bebopDrone) {
    ARCONTROLLER_DICTIONARY_ARG_t *arg = NULL;
    ARCONTROLLER_DICTIONARY_ELEMENT_t *element = NULL;
    HASH_FIND_STR (elementDictionary, ARCONTROLLER_DICTIONARY_SINGLE_KEY, element);
    if (element != NULL)
        {
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_GPSSETTINGSSTATE_RETURNHOMEDELAYCHANGED_DELAY, arg);
        if (arg != NULL)
            {
            uint16_t delay = arg->value.U16;
            [bebopDrone.delegate paDriver:bebopDrone returnHomeDelay:delay];
            }
        }
}

void videoFrameRateChanged(ARCONTROLLER_DICTIONARY_ELEMENT_t *elementDictionary, PABeebopDriver *bebopDrone) {
    ARCONTROLLER_DICTIONARY_ARG_t *arg = NULL;
    ARCONTROLLER_DICTIONARY_ELEMENT_t *element = NULL;
    HASH_FIND_STR (elementDictionary, ARCONTROLLER_DICTIONARY_SINGLE_KEY, element);
    if (element != NULL)
        {
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_PICTURESETTINGSSTATE_VIDEOFRAMERATECHANGED_FRAMERATE, arg);
        if (arg != NULL)
            {
            eARCOMMANDS_ARDRONE3_PICTURESETTINGSSTATE_VIDEOFRAMERATECHANGED_FRAMERATE paFramerate = arg->value.I32;
            PADriverVideoFrameRate frameRate = PADriverVideoFrameRate24;
            
            if (paFramerate == ARCOMMANDS_ARDRONE3_PICTURESETTINGSSTATE_VIDEOFRAMERATECHANGED_FRAMERATE_24_FPS) {
                frameRate = PADriverVideoFrameRate24;
                
            } else if (paFramerate == ARCOMMANDS_ARDRONE3_PICTURESETTINGSSTATE_VIDEOFRAMERATECHANGED_FRAMERATE_25_FPS) {
                frameRate = PADriverVideoFrameRate25;
                
            } else if (paFramerate == ARCOMMANDS_ARDRONE3_PICTURESETTINGSSTATE_VIDEOFRAMERATECHANGED_FRAMERATE_30_FPS) {
                frameRate = PADriverVideoFrameRate30;
            }
            
            [bebopDrone.delegate paDriver:bebopDrone videoFrameRate:frameRate];
            }
        }
}

void wifiOutdoorChanged(ARCONTROLLER_DICTIONARY_ELEMENT_t *elementDictionary, PABeebopDriver *bebopDrone) {
    ARCONTROLLER_DICTIONARY_ARG_t *arg = NULL;
    ARCONTROLLER_DICTIONARY_ELEMENT_t *element = NULL;
    HASH_FIND_STR (elementDictionary, ARCONTROLLER_DICTIONARY_SINGLE_KEY, element);
    if (element != NULL)
        {
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_COMMON_WIFISETTINGSSTATE_OUTDOORSETTINGSCHANGED_OUTDOOR, arg);
        if (arg != NULL)
            {
            uint8_t outdoor = arg->value.U8;
            [bebopDrone.delegate paDriver:bebopDrone wifiOutdoor:outdoor];
            }
        }
}

void videoStabilizationState(ARCONTROLLER_DICTIONARY_ELEMENT_t *elementDictionary, PABeebopDriver *bebopDrone) {
    ARCONTROLLER_DICTIONARY_ARG_t *arg = NULL;
    ARCONTROLLER_DICTIONARY_ELEMENT_t *element = NULL;
    HASH_FIND_STR (elementDictionary, ARCONTROLLER_DICTIONARY_SINGLE_KEY, element);
    if (element != NULL)
        {
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_PICTURESETTINGSSTATE_VIDEOSTABILIZATIONMODECHANGED_MODE, arg);
        if (arg != NULL)
            {
            eARCOMMANDS_ARDRONE3_PICTURESETTINGSSTATE_VIDEOSTABILIZATIONMODECHANGED_MODE mode = arg->value.I32;
            BOOL roll = YES;
            BOOL pitch = YES;
            
            if (ARCOMMANDS_ARDRONE3_PICTURESETTINGSSTATE_VIDEOSTABILIZATIONMODECHANGED_MODE_ROLL_PITCH == mode) {
                roll = YES;
                pitch = YES;
                
            } else if (ARCOMMANDS_ARDRONE3_PICTURESETTINGSSTATE_VIDEOSTABILIZATIONMODECHANGED_MODE_PITCH == mode) {
                roll = NO;
                pitch = YES;
                
            } else if (ARCOMMANDS_ARDRONE3_PICTURESETTINGSSTATE_VIDEOSTABILIZATIONMODECHANGED_MODE_ROLL == mode) {
                roll = YES;
                pitch = NO;
                
            } else if (ARCOMMANDS_ARDRONE3_PICTURESETTINGSSTATE_VIDEOSTABILIZATIONMODECHANGED_MODE_NONE == mode) {
                roll = NO;
                pitch = NO;
            }
            
            [bebopDrone.delegate paDriver:bebopDrone roll:roll pitch:roll];
            }
        }
}

void videoResolutionChanged(ARCONTROLLER_DICTIONARY_ELEMENT_t *elementDictionary, PABeebopDriver *bebopDrone) {
    ARCONTROLLER_DICTIONARY_ARG_t *arg = NULL;
    ARCONTROLLER_DICTIONARY_ELEMENT_t *element = NULL;
    HASH_FIND_STR (elementDictionary, ARCONTROLLER_DICTIONARY_SINGLE_KEY, element);
    if (element != NULL)
        {
        HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_PICTURESETTINGSSTATE_VIDEORESOLUTIONSCHANGED_TYPE, arg);
        if (arg != NULL)
            {
            eARCOMMANDS_ARDRONE3_PICTURESETTINGSSTATE_VIDEORESOLUTIONSCHANGED_TYPE type = arg->value.I32;
            NSLog(@"%d", type);
            
            }
        }
}

// called when a command has been received from the drone
static void onCommandReceived (eARCONTROLLER_DICTIONARY_KEY commandKey, ARCONTROLLER_DICTIONARY_ELEMENT_t *elementDictionary, void *customData) {
    PABeebopDriver *bebopDrone = (__bridge PABeebopDriver*)customData;
    
    // if the command received is a battery state changed
    if ((commandKey == ARCONTROLLER_DICTIONARY_KEY_COMMON_COMMONSTATE_BATTERYSTATECHANGED) &&
        (elementDictionary != NULL)) {
        batteryStateChanged(elementDictionary, bebopDrone);
    }
    // if the command received is a battery state changed
    else if ((commandKey == ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_PILOTINGSTATE_FLYINGSTATECHANGED) &&
             (elementDictionary != NULL)) {
        flyingStateChanged(elementDictionary, bebopDrone);
    }
    // if the command received is a run id changed
    else if ((commandKey == ARCONTROLLER_DICTIONARY_KEY_COMMON_RUNSTATE_RUNIDCHANGED) &&
             (elementDictionary != NULL)) {
        rundIDChanged(elementDictionary, bebopDrone);
    }
    // if drone position changed
//    ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_PILOTINGSTATE_POSITIONCHANGED
    else if ((commandKey == ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_PILOTINGSTATE_GPSLOCATIONCHANGED) &&
             (elementDictionary != NULL)) {
        dronePositionChanged(elementDictionary, bebopDrone);
    }
    // if max Altitude changed.
    else if ((commandKey == ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_PILOTINGSETTINGSSTATE_MAXALTITUDECHANGED) &&
             (elementDictionary != NULL)) {
        maxAltitudeChanged(elementDictionary, bebopDrone);
    }
    // if max tilt changed.
    else if ((commandKey == ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_PILOTINGSETTINGSSTATE_MAXTILTCHANGED) &&
             (elementDictionary != NULL)) {
        maxTiltChanged(elementDictionary, bebopDrone);
    }
    // if MAX DISTANCE CHANGED
    else if ((commandKey == ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_PILOTINGSETTINGSSTATE_MAXDISTANCECHANGED) &&
             (elementDictionary != NULL)) {
        maxDistanceChanged(elementDictionary, bebopDrone);
    }
    // if drone altitude changed
    else if ((commandKey == ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_PILOTINGSTATE_ALTITUDECHANGED) &&
             (elementDictionary != NULL)) {
        altitudeChanged(elementDictionary, bebopDrone);
    }
    // if Drone speed changed in the North East Down coordinates.
    else if ((commandKey == ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_PILOTINGSTATE_SPEEDCHANGED) &&
             (elementDictionary != NULL)) {
        speedChanged(elementDictionary, bebopDrone);
    }
    // if Motor status changed
    else if ((commandKey == ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_SETTINGSSTATE_MOTORERRORSTATECHANGED) && (elementDictionary != NULL)) {
        motorStatusChanged(elementDictionary, bebopDrone);
    }
    // if Motor status about last error
    else if ((commandKey == ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_SETTINGSSTATE_MOTORERRORLASTERRORCHANGED) &&
             (elementDictionary != NULL)) {
        motorStatusLastErrorChanged(elementDictionary, bebopDrone);
    }
    // Orientation of the camera center.
    else if ((commandKey == ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_CAMERASTATE_DEFAULTCAMERAORIENTATION) &&
             (elementDictionary != NULL)) {
        cameraCenterOrientationCommand(elementDictionary, bebopDrone);
    }
    // The number of gps sattelites seen changed.
    else if ((commandKey == ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_GPSSTATE_NUMBEROFSATELLITECHANGED) &&
             (elementDictionary != NULL)) {
        gpsSattelitesNumberChanged(elementDictionary, bebopDrone);
    }
    // Event of picture recording
    else if ((commandKey == ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_MEDIARECORDEVENT_PICTUREEVENTCHANGED) &&
             (elementDictionary != NULL)) {
        pictureEventChanged(elementDictionary, bebopDrone);
    }
    // Event of video recording
    else if ((commandKey == ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_MEDIARECORDEVENT_VIDEOEVENTCHANGED) &&
             (elementDictionary != NULL)) {
        videoEventChanged(elementDictionary, bebopDrone);
    }
    // Drone alert state changed
    else if ((commandKey == ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_PILOTINGSTATE_ALERTSTATECHANGED) &&
             (elementDictionary != NULL)) {
        droneAlertChanged(elementDictionary, bebopDrone);
    }
    // if Status of the camera settings
    else if ((commandKey == ARCONTROLLER_DICTIONARY_KEY_COMMON_CAMERASETTINGSSTATE_CAMERASETTINGSCHANGED) &&
             (elementDictionary != NULL)) {
        cameraSettingsChanged(elementDictionary, bebopDrone);
    }
    // if Max vertical speed changed.
    else if ((commandKey == ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_SPEEDSETTINGSSTATE_MAXVERTICALSPEEDCHANGED) &&
             (elementDictionary != NULL)) {
        maxVerticalSpeedChanged(elementDictionary, bebopDrone);
    }
    // Max rotation speed changed.
    else if ((commandKey == ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_SPEEDSETTINGSSTATE_MAXROTATIONSPEEDCHANGED) &&
               (elementDictionary != NULL)) {
        maxRotationSpeedChanged(elementDictionary, bebopDrone);
    }
    // PICTURE FORMAT CHANGED
    else if ((commandKey == ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_PICTURESETTINGSSTATE_PICTUREFORMATCHANGED) &&
             (elementDictionary != NULL)) {
        pictureFormatChanged(elementDictionary, bebopDrone);
    }
    // MASS STORAGE STATE LIST
    else if ((commandKey == ARCONTROLLER_DICTIONARY_KEY_COMMON_COMMONSTATE_MASSSTORAGESTATELISTCHANGED) &&
             (elementDictionary != NULL)) {
        massStorageListChanged(elementDictionary, bebopDrone);
    }
    // GPS fix changed.
    else if ((commandKey == ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_GPSSETTINGSSTATE_GPSFIXSTATECHANGED) &&
             (elementDictionary != NULL)) {
        gpsStateChanged(elementDictionary, bebopDrone);
    }
    // Return home state changed
    else if ((commandKey == ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_PILOTINGSTATE_NAVIGATEHOMESTATECHANGED) &&
             (elementDictionary != NULL)) {
        returnHomeStateChanged(elementDictionary, bebopDrone);
    }
    // Calibration state
    else if ((commandKey == ARCONTROLLER_DICTIONARY_KEY_COMMON_CALIBRATIONSTATE_MAGNETOCALIBRATIONREQUIREDSTATE) &&
             (elementDictionary != NULL)) {
        calibrationState(elementDictionary, bebopDrone);
    }
    // Banked turn changed
    else if ((commandKey == ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_PILOTINGSETTINGSSTATE_BANKEDTURNCHANGED) &&
             (elementDictionary != NULL)) {
        bankedTurnChanged(elementDictionary, bebopDrone);
    }
    // Return home delay
    else if ((commandKey == ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_GPSSETTINGSSTATE_RETURNHOMEDELAYCHANGED) &&
             (elementDictionary != NULL)) {
        returnHomeDelayChanged(elementDictionary, bebopDrone);
    }
    // Video frame rate
    else if ((commandKey == ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_PICTURESETTINGSSTATE_VIDEOFRAMERATECHANGED) &&
             (elementDictionary != NULL)) {
        videoFrameRateChanged(elementDictionary, bebopDrone);
    }
    // Wifi outdoor state
    else if ((commandKey == ARCONTROLLER_DICTIONARY_KEY_COMMON_WIFISETTINGSSTATE_OUTDOORSETTINGSCHANGED) &&
             (elementDictionary != NULL)) {
        wifiOutdoorChanged(elementDictionary, bebopDrone);
    }
    // Video stabilization
    else if ((commandKey == ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_PICTURESETTINGSSTATE_VIDEOSTABILIZATIONMODECHANGED) &&
             (elementDictionary != NULL)) {
        videoStabilizationState(elementDictionary, bebopDrone);
    }
    // Video resolution
    else if ((commandKey == ARCONTROLLER_DICTIONARY_KEY_ARDRONE3_PICTURESETTINGSSTATE_VIDEORESOLUTIONSCHANGED) &&
             (elementDictionary != NULL)) {
        videoResolutionChanged(elementDictionary, bebopDrone);
    }
}

static eARCONTROLLER_ERROR configDecoderCallback (ARCONTROLLER_Stream_Codec_t codec, void *customData) {
    PABeebopDriver *bebopDrone = (__bridge PABeebopDriver*)customData;
    
    BOOL success = [bebopDrone.delegate paDriver:bebopDrone configureDecoder:codec];
    
    return (success) ? ARCONTROLLER_OK : ARCONTROLLER_ERROR;
}

static eARCONTROLLER_ERROR didReceiveFrameCallback (ARCONTROLLER_Frame_t *frame, void *customData) {
    PABeebopDriver *bebopDrone = (__bridge PABeebopDriver*)customData;
    
    BOOL success = [bebopDrone.delegate paDriver:bebopDrone didReceiveFrame:frame];
    
    return (success) ? ARCONTROLLER_OK : ARCONTROLLER_ERROR;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark resolveService

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)resolveService:(ARService*)service {
    BOOL retval = NO;
    _resolveSemaphore = dispatch_semaphore_create(0);
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(discoveryDidResolve:) name:kARDiscoveryNotificationServiceResolved object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(discoveryDidNotResolve:) name:kARDiscoveryNotificationServiceNotResolved object:nil];
    
    [[ARDiscovery sharedInstance] resolveService:service];
    
    // this semaphore will be signaled in discoveryDidResolve or discoveryDidNotResolve
    dispatch_semaphore_wait(_resolveSemaphore, DISPATCH_TIME_FOREVER);
    
    NSString *ip = [[ARDiscovery sharedInstance] convertNSNetServiceToIp:service];
    if (ip != nil)
        {
        retval = YES;
        }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kARDiscoveryNotificationServiceResolved object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kARDiscoveryNotificationServiceNotResolved object:nil];
    _resolveSemaphore = nil;
    return retval;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)discoveryDidResolve:(NSNotification *)notification {
    dispatch_semaphore_signal(_resolveSemaphore);
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)discoveryDidNotResolve:(NSNotification *)notification {
    NSLog(@"Resolve failed");
    dispatch_semaphore_signal(_resolveSemaphore);
}


////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark SDCardModuleDelegate

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)sdcardModule:(PASDCardModule*)module didFoundMatchingMedias:(NSUInteger)nbMedias {
    [_delegate paDriver:self didFoundMatchingMedias:nbMedias];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)sdcardModule:(PASDCardModule*)module media:(PaMediaModel *)media downloadDidProgress:(int)progress {
    [_delegate paDriver:self media:media downloadDidProgress:progress];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)sdcardModule:(PASDCardModule*)module mediaDownloadDidFinish:(PaMediaModel *)media {
    [_delegate paDriver:self mediaDownloadDidFinish:media];
}


////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private

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
        
        // add the received frame callback to be informed when a frame should be displayed
        if (error == ARCONTROLLER_OK) {
            error = ARCONTROLLER_Device_SetVideoStreamMP4Compliant(_deviceController, 1);
        }
        
        // add the received frame callback to be informed when a frame should be displayed
        if (error == ARCONTROLLER_OK) {
            error = ARCONTROLLER_Device_SetVideoStreamCallbacks(_deviceController, configDecoderCallback,
                                                                didReceiveFrameCallback, NULL , (__bridge void *)(self));
        }
        
        [self sendVideoStreamMode:PADriverVideoStreamModeLowLatency];
        
        // start the device controller (the callback stateChanged should be called soon)
        if (error == ARCONTROLLER_OK) {
            error = ARCONTROLLER_Device_Start (_deviceController);
        }
        
        // we don't need the discovery device anymore
        ARDISCOVERY_Device_Delete (&discoveryDevice);
        
        // if an error occured, inform the delegate that the state is stopped
        if (error != ARCONTROLLER_OK) {
            [self.delegate paDriver:self connectionDidChange:[PABeebopDriver convertDeviceParrotState:ARCONTROLLER_DEVICE_STATE_STOPPED]];
        }
    } else {
        // if an error occured, inform the delegate that the state is stopped
        [self.delegate paDriver:self connectionDidChange:[PABeebopDriver convertDeviceParrotState:ARCONTROLLER_DEVICE_STATE_STOPPED]];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (ARDISCOVERY_Device_t *)createDiscoveryDeviceWithService:(ARService*)service {
    ARDISCOVERY_Device_t *device = NULL;
    eARDISCOVERY_ERROR errorDiscovery = ARDISCOVERY_OK;
    
    device = ARDISCOVERY_Device_New (&errorDiscovery);
    
    if (errorDiscovery == ARDISCOVERY_OK) {
        // need to resolve service to get the IP
        BOOL resolveSucceeded = [self resolveService:service];
        
        if (resolveSucceeded) {
            NSString *ip = [[ARDiscovery sharedInstance] convertNSNetServiceToIp:service];
            int port = (int)[(NSNetService *)service.service port];
            
            if (ip) {
                // create a Wifi discovery device
                errorDiscovery = ARDISCOVERY_Device_InitWifi (device, service.product, [service.name UTF8String], [ip UTF8String], port);
            } else {
                NSLog(@"ip is null");
                errorDiscovery = ARDISCOVERY_ERROR;
            }
        } else {
            NSLog(@"Resolve error");
            errorDiscovery = ARDISCOVERY_ERROR;
        }
        
        if (errorDiscovery != ARDISCOVERY_OK) {
            NSLog(@"Discovery error :%s", ARDISCOVERY_Error_ToString(errorDiscovery));
            ARDISCOVERY_Device_Delete(&device);
        }
    }
    
    return device;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)createSDCardModule {
    eARUTILS_ERROR ftpError = ARUTILS_OK;
    ARUTILS_Manager_t *ftpListManager = NULL;
    ARUTILS_Manager_t *ftpQueueManager = NULL;
    NSString *ip = [[ARDiscovery sharedInstance] convertNSNetServiceToIp:_service];
    
    ftpListManager = ARUTILS_Manager_New(&ftpError);
    if(ftpError == ARUTILS_OK) {
        ftpQueueManager = ARUTILS_Manager_New(&ftpError);
    }
    
    if (ip) {
        if(ftpError == ARUTILS_OK) {
            ftpError = ARUTILS_Manager_InitWifiFtp(ftpListManager, [ip UTF8String], FTP_PORT, ARUTILS_FTP_ANONYMOUS, "");
        }
        
        if(ftpError == ARUTILS_OK) {
            ftpError = ARUTILS_Manager_InitWifiFtp(ftpQueueManager, [ip UTF8String], FTP_PORT, ARUTILS_FTP_ANONYMOUS, "");
        }
    }
    
    _sdCardModule = [[PASDCardModule alloc] initWithFtpListManager:ftpListManager andFtpQueueManager:ftpQueueManager];
    _sdCardModule.delegate = self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (PADriverDeviceState)convertDeviceParrotState:(eARCONTROLLER_DEVICE_STATE)state {
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
+ (PADriverReturnHomeState)convertReturnHomeParrotState:(eARCOMMANDS_ARDRONE3_PILOTINGSTATE_NAVIGATEHOMESTATECHANGED_STATE)state {
    switch (state) {
        case ARCOMMANDS_ARDRONE3_PILOTINGSTATE_NAVIGATEHOMESTATECHANGED_STATE_AVAILABLE:
            return PADriverReturnHomeStateAvailable;
            break;
        case ARCOMMANDS_ARDRONE3_PILOTINGSTATE_NAVIGATEHOMESTATECHANGED_STATE_INPROGRESS:
            return PADriverReturnHomeStateInProgress;
            break;
        case ARCOMMANDS_ARDRONE3_PILOTINGSTATE_NAVIGATEHOMESTATECHANGED_STATE_UNAVAILABLE:
            return PADriverReturnHomeStateUnavailable;
            break;
        case ARCOMMANDS_ARDRONE3_PILOTINGSTATE_NAVIGATEHOMESTATECHANGED_STATE_PENDING:
            return PADriverReturnHomeStatePending;
            break;
            
        default:
            break;
    }
    
    return PADriverReturnHomeStateUnavailable;
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
+ (PADriverPictureRecordingEvent)convertPictureRecordingParrotEvent:(eARCOMMANDS_ARDRONE3_MEDIARECORDEVENT_PICTUREEVENTCHANGED_EVENT)event {
    switch (event) {
        case ARCOMMANDS_ARDRONE3_MEDIARECORDEVENT_PICTUREEVENTCHANGED_EVENT_TAKEN:
            return PADriverPictureRecordingEventTaken;
            break;
        case ARCOMMANDS_ARDRONE3_MEDIARECORDEVENT_PICTUREEVENTCHANGED_EVENT_FAILED:
            return PADriverPictureRecordingEventFailed;
            break;
            
        default:
            break;
    }
    
    return PADriverPictureRecordingEventFailed;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (PADriverVideoRecordingEvent)convertVideoRecordingParrotEvent:(eARCOMMANDS_ARDRONE3_MEDIARECORDEVENT_VIDEOEVENTCHANGED_EVENT)event {
    switch (event) {
        case ARCOMMANDS_ARDRONE3_MEDIARECORDEVENT_VIDEOEVENTCHANGED_EVENT_START:
            return PADriverVideoRecordingEventStart;
            break;
        case ARCOMMANDS_ARDRONE3_MEDIARECORDEVENT_VIDEOEVENTCHANGED_EVENT_STOP:
            return PADriverVideoRecordingEventStop;
            break;
        case ARCOMMANDS_ARDRONE3_MEDIARECORDEVENT_VIDEOEVENTCHANGED_EVENT_FAILED:
            return PADriverVideoRecordingEventFailed;
            break;
            
        default:
            break;
    }
    
    return PADriverVideoRecordingEventStop;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (PADriverVideoRecordingStatus)convertVideoRecordingParrotStatus:(eARCOMMANDS_ARDRONE3_MEDIARECORDEVENT_VIDEOEVENTCHANGED_ERROR)status {
    switch (status) {
        case ARCOMMANDS_ARDRONE3_MEDIARECORDEVENT_VIDEOEVENTCHANGED_ERROR_OK:
            return PADriverVideoRecordingStatusOK;
            break;
        case ARCOMMANDS_ARDRONE3_MEDIARECORDEVENT_VIDEOEVENTCHANGED_ERROR_UNKNOWN:
            return PADriverVideoRecordingStatusUnknown;
            break;
        case ARCOMMANDS_ARDRONE3_MEDIARECORDEVENT_VIDEOEVENTCHANGED_ERROR_NOTAVAILABLE:
            return PADriverVideoRecordingStatusNotAvailable;
            break;
        
        case ARCOMMANDS_ARDRONE3_MEDIARECORDEVENT_VIDEOEVENTCHANGED_ERROR_BUSY:
            return PADriverVideoRecordingStatusBusy;
            break;
        case ARCOMMANDS_ARDRONE3_MEDIARECORDEVENT_VIDEOEVENTCHANGED_ERROR_MEMORYFULL:
            return PADriverVideoRecordingStatusMemoryFull;
            break;
        case ARCOMMANDS_ARDRONE3_MEDIARECORDEVENT_VIDEOEVENTCHANGED_ERROR_LOWBATTERY:
            return PADriverVideoRecordingStatusLowBattery;
            break;
        case ARCOMMANDS_ARDRONE3_MEDIARECORDEVENT_VIDEOEVENTCHANGED_ERROR_AUTOSTOPPED:
            return PADriverVideoRecordingStatusAutoStopped;
            break;
            
        default:
            break;
    }
    
    return PADriverVideoRecordingStatusUnknown;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (PADriverPictureRecordingStatus)convertPictureRecordingParrotStatus:(eARCOMMANDS_ARDRONE3_MEDIARECORDEVENT_PICTUREEVENTCHANGED_ERROR)status {
    switch (status) {
        case ARCOMMANDS_ARDRONE3_MEDIARECORDEVENT_PICTUREEVENTCHANGED_ERROR_OK:
            return PADriverPictureRecordingStatusOK;
            break;
        case ARCOMMANDS_ARDRONE3_MEDIARECORDEVENT_PICTUREEVENTCHANGED_ERROR_UNKNOWN:
            return PADriverPictureRecordingStatusUnknown;
            break;
        case ARCOMMANDS_ARDRONE3_MEDIARECORDEVENT_PICTUREEVENTCHANGED_ERROR_NOTAVAILABLE:
            return PADriverPictureRecordingStatusNotAvailable;
            break;
            
        case ARCOMMANDS_ARDRONE3_MEDIARECORDEVENT_VIDEOEVENTCHANGED_ERROR_BUSY:
            return PADriverPictureRecordingStatusBusy;
            break;
        case ARCOMMANDS_ARDRONE3_MEDIARECORDEVENT_PICTUREEVENTCHANGED_ERROR_MEMORYFULL:
            return PADriverPictureRecordingStatusMemoryFull;
            break;
        case ARCOMMANDS_ARDRONE3_MEDIARECORDEVENT_PICTUREEVENTCHANGED_ERROR_LOWBATTERY:
            return PADriverPictureRecordingStatusLowBattery;
            break;
            
        default:
            break;
    }
    
    return PADriverPictureRecordingStatusUnknown;
}

@end
