// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "NSCache+DFImageManager.h"
#import <UIKit/UIKit.h>

@implementation NSCache (DFImageManager)

+ (nonnull NSCache *)df_sharedImageCache {
    static NSCache *cache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [NSCache new];
        cache.totalCostLimit = [self df_recommendedTotalCostLimit];
    });
    return cache;
}

+ (NSUInteger)df_recommendedTotalCostLimit {
    static NSUInteger recommendedSize;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
#if TARGET_OS_WATCH
        recommendedSize = 1024 * 1024 * 20; /* 20 Mb */
#else
        NSProcessInfo *info = [NSProcessInfo processInfo];
        CGFloat ratio = info.physicalMemory <= (1024 * 1024 * 512 /* 512 Mb */) ? 0.1f : 0.2f;
        recommendedSize = (NSUInteger)MAX(1024 * 1024 * 50 /* 50 Mb */, info.physicalMemory * ratio);
#endif
    });
    return recommendedSize;
}

@end
