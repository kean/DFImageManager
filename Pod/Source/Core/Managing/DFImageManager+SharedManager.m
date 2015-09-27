// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFCompositeImageManager.h"
#import "DFImageCache.h"
#import "DFImageDecoder.h"
#import "DFImageManager.h"
#import "DFImageManagerConfiguration.h"
#import "DFImageProcessor.h"
#import "DFURLImageFetcher.h"
#import <libkern/OSAtomic.h>

#if DF_SUBSPEC_GIF_ENABLED
#import "DFImageManagerKit+GIF.h"
#endif

#if DF_SUBSPEC_WEBP_ENABLED
#import "DFImageManagerKit+WebP.h"
#endif

#if DF_SUBSPEC_PHOTOSKIT_ENABLED
#import "DFImageManagerKit+PhotosKit.h"
#endif

#if DF_SUBSPEC_AFNETWORKING_ENABLED
#import "DFImageManagerKit+AFNetworking.h"
#import <AFNetworking/AFHTTPSessionManager.h>
#endif

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
    DFImageManagerConfiguration *conf = [self _defaultImageManagerConfiguration];
    
    NSMutableArray *managers = [NSMutableArray new];
    
#if DF_SUBSPEC_AFNETWORKING_ENABLED
    [managers addObject:({
        AFHTTPSessionManager *sessionManager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:[self _defaultSessionConfiguration]];
        sessionManager.responseSerializer = [AFHTTPResponseSerializer new];
        conf.fetcher = [[DFAFImageFetcher alloc] initWithSessionManager:sessionManager];
        [[DFImageManager alloc] initWithConfiguration:conf];
    })];
#else
    [managers addObject:({
        conf.fetcher = [[DFURLImageFetcher alloc] initWithSessionConfiguration:[self _defaultSessionConfiguration]];
        [[DFImageManager alloc] initWithConfiguration:conf];
    })];
#endif

#if DF_SUBSPEC_PHOTOSKIT_ENABLED
    [managers addObject:({
        conf.fetcher = [DFPhotosKitImageFetcher new];
        [[DFImageManager alloc] initWithConfiguration:conf];
    })];
#endif
    
    return managers.count > 1 ? [[DFCompositeImageManager alloc] initWithImageManagers:managers] : managers.firstObject;
}


+ (DFImageManagerConfiguration *)_defaultImageManagerConfiguration {
    DFImageManagerConfiguration *conf = [DFImageManagerConfiguration new];
    
    conf.decoder = ({
        NSMutableArray *decoders = [NSMutableArray new];
#if DF_SUBSPEC_GIF_ENABLED
        [decoders addObject:[DFAnimatedImageDecoder new]];
#endif
#if DF_SUBSPEC_WEBP_ENABLED
        [decoders addObject:[DFWebPImageDecoder new]];
#endif
        [decoders addObject:[DFImageDecoder new]];
        decoders.count > 1 ? [[DFCompositeImageDecoder alloc] initWithDecoders:decoders] : decoders.firstObject;
    });
    
    conf.processor = ({
        id<DFImageProcessing> processor = [DFImageProcessor new];
#if DF_SUBSPEC_GIF_ENABLED
        processor = [[DFAnimatedImageProcessor alloc] initWithProcessor:processor];
#endif
        processor;
    });
    
    conf.cache = [DFImageCache new];
    return conf;
}

+ (NSURLSessionConfiguration *)_defaultSessionConfiguration {
    NSURLSessionConfiguration *conf = [NSURLSessionConfiguration defaultSessionConfiguration];
    conf.URLCache = [[NSURLCache alloc] initWithMemoryCapacity:0 diskCapacity:1024 * 1024 * 200 diskPath:@"com.github.kean.default_image_cache"];
#if DF_SUBSPEC_WEBP_ENABLED
    conf.HTTPAdditionalHeaders = @{ @"Accept" : @"image/webp,image/*;q=0.8" };
#else
    conf.HTTPAdditionalHeaders = @{ @"Accept" : @"image/*" };
#endif
    conf.timeoutIntervalForRequest = 60.f;
    conf.timeoutIntervalForResource = 360.f;
    return conf;
}

@end
