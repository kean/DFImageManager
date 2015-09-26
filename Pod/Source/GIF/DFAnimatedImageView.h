// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFImageView.h"
#import <FLAnimatedImage/FLAnimatedImage.h>

/*! An image view extends UIImageView class with image fetching functionality. It also adds other features like managing request priorities and more.
 @note The DFImageView uses FLAnimatedImageView to enable animated GIF playback. The playback is enabled by default and can be disabled using allowsGIFPlayback property. The DFImageView doesn't override any of the FLAnimatedImageView methods so should get the same experience as when using the FLAnimatedImageView class directly. The only addition is a new - (void)displayImage:(UIImage *)image method that supports DFAnimatedImage objects and will automatically start GIF playback when passed an object of that class.
 */
@interface DFAnimatedImageView : DFImageView

/*! Inner animated image view used for GIF playback.
 */
@property (nonnull, nonatomic, readonly) FLAnimatedImageView *animatedImageView;

/*! If the value is YES the receiver will start a GIF playback as soon as the image is displayed. Default value is YES.
 */
@property (nonatomic) BOOL allowsGIFPlayback;

/*! Displays a given image. Automatically starts GIF playback when given a DFAnimatedImage object and when the GIF playback is enabled.
 @note This method is always included in compilation even if the The 'GIF' subspec is not installed.
 */
- (void)displayImage:(nullable UIImage *)image;

@end
