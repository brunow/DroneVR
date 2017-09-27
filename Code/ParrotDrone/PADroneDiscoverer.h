//
//  DroneDiscoverer.h
//  SDKSample
//  Taken from Parrot sample code

#import <Foundation/Foundation.h>

@class PADroneDiscoverer;

@protocol PADroneDiscovererDelegate<NSObject>

/**
 * Called when the device found list is updated
 * Called on the main thread
 * @param droneDiscoverer the drone discoverer concerned
 * @param dronesList the list of found compatible ARService
 */
- (void)droneDiscoverer:(PADroneDiscoverer*)droneDiscoverer didUpdateDronesList:(NSArray*)dronesList;

@end

@interface PADroneDiscoverer : NSObject

@property (nonatomic, weak) id<PADroneDiscovererDelegate> delegate;

- (void)startDiscovering;
- (void)stopDiscovering;

@end
