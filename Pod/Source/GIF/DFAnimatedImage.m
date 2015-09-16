// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFAnimatedImage.h"

@implementation DFAnimatedImage

- (instancetype)initWithAnimatedImage:(FLAnimatedImage *)animatedImage {
    if (self = [super initWithCGImage:animatedImage.posterImage.CGImage]) {
        _animatedImage = animatedImage;
    }
    return self;
}

+ (nullable instancetype)animatedImageWithGIFData:(nullable NSData *)data {
    FLAnimatedImage *animatedImage = [FLAnimatedImage animatedImageWithGIFData:data];
    return animatedImage ? [[DFAnimatedImage alloc] initWithAnimatedImage:animatedImage] : nil;
}

/*! See https://en.wikipedia.org/wiki/List_of_file_signatures
 */
+ (BOOL)isAnimatedGIFData:(nullable NSData *)data {
    const NSInteger sigLength = 3;
    if (data.length < sigLength) {
        return NO;
    }
    uint8_t sig[sigLength];
    [data getBytes:&sig length:sigLength];
    return sig[0] == 0x47 && sig[1] == 0x49 && sig[2] == 0x46;
}

@end
