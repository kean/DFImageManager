// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFImageView.h"
#import <FLAnimatedImage/FLAnimatedImage.h>

/*! The DFAnimatedImageView uses FLAnimatedImageView to enable animated GIF playback. 
 @note The playback is enabled by default and can be disabled using allowsGIFPlayback property.
 */
@interface DFAnimatedImageView : DFImageView

/*! Inner animated image view used for GIF playback.
 */
@property (nonnull, nonatomic, readonly) FLAnimatedImageView *animatedImageView;

/*! If the value is YES the receiver will start a GIF playback as soon as the image is displayed. Default value is YES.
 */
@property (nonatomic) BOOL allowsGIFPlayback;

/*! Displays a given image. Automatically starts GIF playback when given a DFAnimatedImage object and when the GIF playback is enabled.
 */
- (void)displayImage:(nullable UIImage *)image;

@end
