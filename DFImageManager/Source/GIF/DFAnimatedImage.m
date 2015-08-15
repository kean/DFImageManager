// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "DFAnimatedImage.h"

@implementation DFAnimatedImage

- (instancetype)initWithAnimatedImage:(FLAnimatedImage *)animatedImage {
    if (self = [super initWithCGImage:animatedImage.posterImage.CGImage]) {
        _animatedImage = animatedImage;
    }
    return self;
}

- (nullable instancetype)initWithAnimatedGIFData:(nullable NSData *)data {
    FLAnimatedImage *animatedImage = [FLAnimatedImage animatedImageWithGIFData:data];
    if (!animatedImage) {
        return nil;
    }
    return [self initWithAnimatedImage:animatedImage];
}

+ (nullable instancetype)animatedImageWithGIFData:(nullable NSData *)data {
    return [[DFAnimatedImage alloc] initWithAnimatedGIFData:data];
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
