// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import <UIKit/UIKit.h>
#import <FLAnimatedImage/FLAnimatedImage.h>

/*! The DFAnimatedImage subclasses UIImage and represents a poster image for the underlying animated image. It is a regular UIImage that doesn't override any of the native UIImage behaviours it can be used anywhere where a regular `UIImage` can be used.
 */
@interface DFAnimatedImage : UIImage

/* The animated image that the receiver was initialized with. An `FLAnimatedImage`'s job is to deliver frames in a highly performant way and works in conjunction with `FLAnimatedImageView`.
 */
@property (nonnull, nonatomic, readonly) FLAnimatedImage *animatedImage;

/*! Initializes the DFAnimatedImage with an instance of FLAnimatedImage class.
 */
- (nonnull instancetype)initWithAnimatedImage:(nonnull FLAnimatedImage *)animatedImage NS_DESIGNATED_INITIALIZER;

/*! Returns the DFAnimatedImage object with an instance of FLAnimatedImage class created from a given data.
 */
+ (nullable instancetype)animatedImageWithGIFData:(nullable NSData *)data;

/*! Returns YES if the data represents an animated GIF.
 */
+ (BOOL)isAnimatedGIFData:(nullable NSData *)data;

@end
