// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFImageCache.h"
#import "DFImageManager.h"
#import "DFImageManagerConfiguration.h"
#import "DFImageProcessor.h"
#import "DFURLImageFetcher.h"
#import <libkern/OSAtomic.h>

@implementation DFImageManager (SharedManager)

static id<DFImageManaging> _sharedManager;
static OSSpinLock _lock = OS_SPINLOCK_INIT;

+ (nonnull id<DFImageManaging>)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!_sharedManager) {
            _sharedManager = [self _createDefaultManager];
        }
    });
    
    id<DFImageManaging> manager;
    OSSpinLockLock(&_lock);
    manager = _sharedManager;
    OSSpinLockUnlock(&_lock);
    return manager;
}

+ (void)setSharedManager:(nonnull id<DFImageManaging>)manager {
    OSSpinLockLock(&_lock);
    _sharedManager = manager;
    OSSpinLockUnlock(&_lock);
}

+ (id<DFImageManaging>)_createDefaultManager {
    DFURLImageFetcher *fetcher = [[DFURLImageFetcher alloc] initWithSessionConfiguration:({
        NSURLSessionConfiguration *conf = [NSURLSessionConfiguration defaultSessionConfiguration];
        conf.URLCache = [[NSURLCache alloc] initWithMemoryCapacity:0 diskCapacity:1024 * 1024 * 200 diskPath:@"com.github.kean.default_image_cache"];
        conf.timeoutIntervalForRequest = 60.f;
        conf.timeoutIntervalForResource = 360.f;
        conf;
    })];
    return [[DFImageManager alloc] initWithConfiguration:[DFImageManagerConfiguration configurationWithFetcher:fetcher processor:[DFImageProcessor new] cache:[DFImageCache new]]];
}

@end
