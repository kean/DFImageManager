// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import <UIKit/UIKit.h>
#import <FLAnimatedImage/FLAnimatedImage.h>

/*! The DFAnimatedImage subclasses UIImage and represents a poster image for the underlying animated image. It can be used anywhere where a regular `UIImage` can be used.
 */
@interface DFAnimatedImage : UIImage

/* The animated image that the receiver was initialized with. An `FLAnimatedImage`'s job is to deliver frames in a highly performant way and works in conjunction with `FLAnimatedImageView`.
 */
@property (nonnull, nonatomic, readonly) FLAnimatedImage *animatedImage;

/*! Initializes the DFAnimatedImage with an instance of FLAnimatedImage class and poster image.
 */
- (nonnull instancetype)initWithAnimatedImage:(nonnull FLAnimatedImage *)animatedImage posterImage:(nonnull CGImageRef)posterImage posterImageScale:(CGFloat)posterImageScale posterImageOrientation:(UIImageOrientation)posterImageOrientation NS_DESIGNATED_INITIALIZER;

@end
