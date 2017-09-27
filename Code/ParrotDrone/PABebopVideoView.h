//
//  BebopVideoView.h
//  SDKSample
//  Taken from Parrot sample code

#import <UIKit/UIKit.h>
#import <libARController/ARController.h>

@interface PABebopVideoView : UIView

- (BOOL)configureDecoder:(ARCONTROLLER_Stream_Codec_t)codec;
- (BOOL)displayFrame:(ARCONTROLLER_Frame_t *)frame;

@end
