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

#import "DFImageCache.h"
#import "NSCache+DFImageManager.h"


@interface _DFImageCacheEntry : NSObject

@property (nonatomic) UIImage *image;
@property (nonatomic) NSTimeInterval creationDate;

+ (instancetype)entryWithImage:(UIImage *)image;

@end

@implementation _DFImageCacheEntry

+ (instancetype)entryWithImage:(UIImage *)image {
    _DFImageCacheEntry *entry = [_DFImageCacheEntry new];
    entry.image = image;
    entry.creationDate = CACurrentMediaTime();
    return entry;
}

@end


@implementation DFImageCache

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithCache:(NSCache *)cache {
    if (self = [super init]) {
        _cache = cache;
        _maximumEntryAge = FLT_MAX;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}

- (instancetype)init {
    NSCache *cache = [NSCache new];
    cache.totalCostLimit = [NSCache df_recommendedTotalCostLimit];
    return [self initWithCache:cache];
}

#pragma mark - <DFImageCache>

- (UIImage *)cacheImageForKey:(id<NSCopying>)key {
    if (key != nil) {
        _DFImageCacheEntry *entry = [_cache objectForKey:key];
        if (entry != nil) {
            if (CACurrentMediaTime() - entry.creationDate < self.maximumEntryAge) {
                return entry.image;
            } else {
                [_cache removeObjectForKey:key];
            }
        }
    }
    return nil;
}


- (void)storeImage:(UIImage *)image forKey:(id<NSCopying>)key {
    if (image != nil && key != nil) {
        NSUInteger cost = [self _costForImage:image];
        [_cache setObject:[_DFImageCacheEntry entryWithImage:image] forKey:key cost:cost];
    }
}

- (void)removeAllObjects {
    [_cache removeAllObjects];
}

#pragma mark -

- (NSUInteger)_costForImage:(UIImage *)image {
    CGImageRef imageRef = image.CGImage;
    NSUInteger bitsPerPixel = CGImageGetBitsPerPixel(imageRef);
    return (CGImageGetWidth(imageRef) * CGImageGetHeight(imageRef) * bitsPerPixel) / 8; // Return number of bytes in image bitmap.
}

- (void)_didReceiveMemoryWarning:(NSNotification *__unused)notification {
    [self.cache removeAllObjects];
}

@end
