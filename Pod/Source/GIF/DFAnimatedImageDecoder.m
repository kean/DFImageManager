// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFAnimatedImageDecoder.h"
#import "DFAnimatedImage.h"

@implementation DFAnimatedImageDecoder

- (UIImage *)imageWithData:(NSData *)data partial:(BOOL)partial {
    if (![self _isGIFData:data]) {
        return nil;
    }
    FLAnimatedImage *animatedImage = [FLAnimatedImage animatedImageWithGIFData:data];
    if (!animatedImage) {
        return nil;
    }
    UIImage *posterImage = animatedImage.posterImage;
    CGImageRef posterImageRef = posterImage.CGImage;
    if (!posterImageRef) {
        return nil;
    }
    return [[DFAnimatedImage alloc] initWithAnimatedImage:animatedImage posterImage:posterImageRef posterImageScale:posterImage.scale posterImageOrientation:posterImage.imageOrientation];
}

/*! See https://en.wikipedia.org/wiki/List_of_file_signatures
 */
- (BOOL)_isGIFData:(NSData *)data {
    const NSInteger sigLength = 3;
    if (data.length < sigLength) {
        return NO;
    }
    uint8_t sig[sigLength];
    [data getBytes:&sig length:sigLength];
    return sig[0] == 0x47 && sig[1] == 0x49 && sig[2] == 0x46;
}

@end
