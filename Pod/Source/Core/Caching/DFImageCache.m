// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFCachedImageResponse.h"
#import "DFImageCache.h"
#import "DFImageManagerDefines.h"
#import "NSCache+DFImageManager.h"

@implementation DFImageCache

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (nonnull instancetype)initWithCache:(nonnull NSCache *)cache {
    if (self = [super init]) {
        _cache = cache;
#if __IPHONE_OS_VERSION_MIN_REQUIRED && !__WATCH_OS_VERSION_MIN_REQUIRED
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeAllObjects) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
#endif
    }
    return self;
}

- (instancetype)init {
    return [self initWithCache:[NSCache df_sharedImageCache]];
}

#pragma mark - <DFImageCaching>

- (nullable DFCachedImageResponse *)cachedImageResponseForKey:(nullable id<NSCopying>)key {
    DFCachedImageResponse *response = [_cache objectForKey:key];
    if (response) {
        if (response.expirationDate > CFAbsoluteTimeGetCurrent()) {
            return response;
        } else {
            [_cache removeObjectForKey:key];
        }
    }
    return nil;
}

- (void)storeImageResponse:(nullable DFCachedImageResponse *)response forKey:(nullable id<NSCopying>)key {
    if (response && key) {
        [_cache setObject:response forKey:key cost:[self costForImageResponse:response]];
    }
}

- (void)removeAllObjects {
    [_cache removeAllObjects];
}

- (NSUInteger)costForImageResponse:(nonnull DFCachedImageResponse *)cachedResponse {
    UIImage *image = cachedResponse.image;
    CGImageRef imageRef = image.CGImage;
    return (CGImageGetWidth(imageRef) * CGImageGetHeight(imageRef) * CGImageGetBitsPerPixel(imageRef)) / 8;
}

@end
