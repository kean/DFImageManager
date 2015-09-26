// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFAnimatedImage.h"

@implementation DFAnimatedImage

- (instancetype)initWithAnimatedImage:(FLAnimatedImage *)animatedImage posterImage:(CGImageRef)posterImage posterImageScale:(CGFloat)posterImageScale posterImageOrientation:(UIImageOrientation)posterImageOrientation {
    if (self = [super initWithCGImage:posterImage scale:posterImageScale orientation:posterImageOrientation]) {
        _animatedImage = animatedImage;
    }
    return self;
}

@end
