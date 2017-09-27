//
//  SDCardModule.h
//  SDKSample
//  Taken from Parrot sample code

#import <Foundation/Foundation.h>
#include <libARUtils/ARUtils.h>
#import "PaMediaModel.h"

@class PASDCardModule;

@protocol PASDCardModuleDelegate <NSObject>
@required
/**
 * Called before medias will be downloaded
 * Called on the main thread
 * @param module the sdcard module
 * @param nbMedias the number of medias that will be downloaded
 */
- (void)sdcardModule:(PASDCardModule*)module didFoundMatchingMedias:(NSUInteger)nbMedias;

/**
 * Called each time the progress of a download changes
 * Called on the main thread
 * @param module the sdcard module
 * @param mediaName the name of the media
 * @param progress the progress of its download (from 0 to 100)
 */
- (void)sdcardModule:(PASDCardModule*)module media:(PaMediaModel *)media downloadDidProgress:(int)progress;

/**
 * Called when a media download has ended
 * Called on the main thread
 * @param module the sdcard module
 * @param mediaName the name of the media
 */
//- (void)sdcardModule:(PASDCardModule*)module mediaDownloadDidFinish:(NSString*)mediaName;

- (void)sdcardModule:(PASDCardModule*)module mediaDownloadDidFinish:(PaMediaModel *)media;

@end

@interface PASDCardModule : NSObject

@property (nonatomic, weak) id<PASDCardModuleDelegate>delegate;

- (id)initWithFtpListManager:(ARUTILS_Manager_t*)ftpListManager andFtpQueueManager:(ARUTILS_Manager_t*)ftpQueueManager;
- (void)getFlightMedias:(NSString*)runId;
- (void)getTodaysFlightMedias;
- (void)getAllFlightMedias;
- (void)cancelGetMedias;

@end
