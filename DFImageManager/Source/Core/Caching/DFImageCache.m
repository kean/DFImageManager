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

#import "DFCachedImageResponse.h"
#import "DFImageCache.h"
#import "NSCache+DFImageManager.h"

#if DF_IMAGE_MANAGER_GIF_AVAILABLE
#import "DFImageManagerKit+GIF.h"
#endif

@implementation DFImageCache

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (nonnull instancetype)initWithCache:(nonnull NSCache *)cache {
    if (self = [super init]) {
        _cache = cache;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}

- (instancetype)init {
    return [self initWithCache:[NSCache df_sharedImageCache]];
}

#pragma mark - <DFImageCaching>

- (nullable DFCachedImageResponse *)cachedImageResponseForKey:(nullable id<NSCopying>)key {
    DFCachedImageResponse *cachedImage = [_cache objectForKey:key];
    if (cachedImage) {
        if (cachedImage.expirationDate > CACurrentMediaTime()) {
            return cachedImage;
        } else {
            [_cache removeObjectForKey:key];
        }
    }
    return nil;
}

- (void)storeImageResponse:(nullable DFCachedImageResponse *)cachedResponse forKey:(nullable id<NSCopying>)key {
    if (cachedResponse && key) {
        NSUInteger cost = [self costForImageResponse:cachedResponse];
        [_cache setObject:cachedResponse forKey:key cost:cost];
    }
}

- (void)removeAllObjects {
    [_cache removeAllObjects];
}

#pragma mark -

- (NSUInteger)costForImageResponse:(nonnull DFCachedImageResponse *)cachedResponse {
    UIImage *image = cachedResponse.image;
    CGImageRef imageRef = image.CGImage;
    NSUInteger bitsPerPixel = CGImageGetBitsPerPixel(imageRef);
    NSUInteger cost = (CGImageGetWidth(imageRef) * CGImageGetHeight(imageRef) * bitsPerPixel) / 8; // Return number of bytes in image bitmap.
#if DF_IMAGE_MANAGER_GIF_AVAILABLE
    if ([image isKindOfClass:[DFAnimatedImage class]]) {
        DFAnimatedImage *animatedImage = (id)image;
        cost += animatedImage.animatedImage.data.length;
    }
#endif
    return cost;
}

- (void)_didReceiveMemoryWarning:(NSNotification *__unused)notification {
    [self.cache removeAllObjects];
}

@end
