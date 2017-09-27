//
//  DroneDiscoverer.m
//  SDKSample
//  Taken from Parrot sample code

#import "PADroneDiscoverer.h"
#import <libARDiscovery/ARDISCOVERY_BonjourDiscovery.h>
@import UIKit;

@implementation PADroneDiscoverer

- (void)setDelegate:(id<PADroneDiscovererDelegate>)delegate {
    _delegate = delegate;
    
    [self sendCurrentDivices];
}

- (void)sendCurrentDivices {
    if (_delegate && [_delegate respondsToSelector:@selector(droneDiscoverer:didUpdateDronesList:)]) {
        [_delegate droneDiscoverer:self didUpdateDronesList:[self compatibleDronesWithServices:[[ARDiscovery sharedInstance] getCurrentListOfDevicesServices]]];
    }
}

- (void)startDiscovering {
    [self registerNotifications];
    [[ARDiscovery sharedInstance] start];
    [self sendCurrentDivices];
}

- (void)stopDiscovering {
    [[ARDiscovery sharedInstance] stop];
    [self unregisterNotifications];
}

#pragma mark private

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSArray *)compatibleDronesWithServices:(NSArray *)services {
    NSMutableArray *compatibleServices = [NSMutableArray array];
    
    for (ARService *service in services) {
        if (service.product == ARDISCOVERY_PRODUCT_ARDRONE || service.product == ARDISCOVERY_PRODUCT_BEBOP_2 || service.product == ARDISCOVERY_PRODUCT_MINIDRONE_EVO_BRICK) { // Get only bebop drone
            [compatibleServices addObject:service];
        }
        
//        [compatibleServices addObject:service];
    }
    
    return [compatibleServices copy];
}

#pragma mark - application notifications
- (void)enterForeground:(NSNotification*)notification {
    [[ARDiscovery sharedInstance] start];
}

- (void)enteredBackground:(NSNotification*)notification {
    [[ARDiscovery sharedInstance] stop];
}

#pragma mark notification registration
- (void)registerNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(discoveryDidUpdateServices:)
                                                 name:kARDiscoveryNotificationServicesDevicesListUpdated
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enteredBackground:) name: UIApplicationDidEnterBackgroundNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterForeground:) name: UIApplicationWillEnterForegroundNotification object: nil];
}

- (void)unregisterNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kARDiscoveryNotificationServicesDevicesListUpdated object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name: UIApplicationDidEnterBackgroundNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name: UIApplicationWillEnterForegroundNotification object: nil];

}

#pragma mark ARDiscovery notification
- (void)discoveryDidUpdateServices:(NSNotification *)notification {
//    NSArray *drones = [self compatibleDronesWithServices:[[notification userInfo] objectForKey:kARDiscoveryServicesList]];
//    NSLog(@"discoveryDidUpdateServices count %d", drones.count);
    
    // reload the data in the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_delegate && [_delegate respondsToSelector:@selector(droneDiscoverer:didUpdateDronesList:)]) {
            [_delegate droneDiscoverer:self didUpdateDronesList:[self compatibleDronesWithServices:[[notification userInfo] objectForKey:kARDiscoveryServicesList]]];
        }
    });
}

@end
