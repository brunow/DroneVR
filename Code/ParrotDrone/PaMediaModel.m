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

#import "PaMediaModel.h"

#import <ImageIO/ImageIO.h>
#import <libARMedia/ARMedia.h>
#import <libARMedia/ARMEDIA_Object.h>
@import CoreLocation;

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation PaMediaModel

////////////////////////////////////////////////////////////////////////////////////////////////////
- (instancetype)initWithMedia:(ARDATATRANSFER_Media_t *)media {
    self = [self init];
    if (self) {
        self.product = media->product;
        self.name = [NSString stringWithUTF8String:media->name];
        self.filepath = [NSString stringWithUTF8String:media->filePath];
        self.uuid = [NSString stringWithUTF8String:media->uuid];
        self.remotePath = [NSString stringWithUTF8String:media->remotePath];
//        self.date = media.date;
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (UIImage *)loadImage {
    return [[UIImage alloc] initWithContentsOfFile:self.filepath];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)deleteFile {
}

// https://oleb.net/blog/2011/09/accessing-image-properties-without-loading-the-image-into-memory/
////////////////////////////////////////////////////////////////////////////////////////////////////
- (CLLocation *)location {
    NSURL *imageFileURL = [NSURL fileURLWithPath:self.filepath];
    CGImageSourceRef imageSource = CGImageSourceCreateWithURL((CFURLRef)imageFileURL, NULL);
    if (imageSource == NULL) {
        // Error loading image
        return nil;
    }
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             @NO, (NSString *)kCGImageSourceShouldCache,
                             nil];
    
    CFDictionaryRef imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, (CFDictionaryRef)options);
    if (imageProperties) {
//        NSNumber *width = (NSNumber *)CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelWidth);
//        NSNumber *height = (NSNumber *)CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelHeight);
//        NSLog(@"Image dimensions: %@ x %@ px", width, height);
        
//        CFDictionaryRef exif = CFDictionaryGetValue(imageProperties, kCGImagePropertyExifDictionary);
//        if (exif) {
//            NSString *dateTakenString = (NSString *)CFDictionaryGetValue(exif, kCGImagePropertyExifDateTimeOriginal);
//            NSLog(@"Date Taken: %@", dateTakenString);
//            CFRelease(exif);
//        }
        
        CFDictionaryRef gps = CFDictionaryGetValue(imageProperties, kCGImagePropertyGPSDictionary);
        if (gps) {
            NSString *altitudeString = (NSString *)CFDictionaryGetValue(gps, kCGImagePropertyGPSAltitude);
            NSString *altitudeRef = (NSString *)CFDictionaryGetValue(gps, kCGImagePropertyGPSAltitudeRef);
            NSString *latitudeString = (NSString *)CFDictionaryGetValue(gps, kCGImagePropertyGPSLatitude);
            NSString *latitudeRef = (NSString *)CFDictionaryGetValue(gps, kCGImagePropertyGPSLatitudeRef);
            NSString *longitudeString = (NSString *)CFDictionaryGetValue(gps, kCGImagePropertyGPSLongitude);
            NSString *longitudeRef = (NSString *)CFDictionaryGetValue(gps, kCGImagePropertyGPSLongitudeRef);
            NSLog(@"GPS Coordinates: %@ %@ / %@ %@", longitudeString, longitudeRef, latitudeString, latitudeRef);
            NSLog(@"GPS altitude: %@ %@", altitudeString, altitudeRef);
            CFRelease(gps);
        }
        
        CFRelease(imageProperties);
    }
    
    CFRelease(imageSource);
    
    return  nil;
}

//eARDISCOVERY_PRODUCT product;
//char name[ARDATATRANSFER_MEDIA_NAME_SIZE];
//char filePath[ARDATATRANSFER_MEDIA_PATH_SIZE];
//char date[ARDATATRANSFER_MEDIA_DATE_SIZE];
//char uuid[ARDATATRANSFER_MEDIA_UUID_SIZE];
//char remotePath[ARUTILS_FTP_MAX_PATH_SIZE];
//char remoteThumb[ARUTILS_FTP_MAX_PATH_SIZE];
//double size;
//uint8_t *thumbnail;
//uint32_t thumbnailSize;

@end
