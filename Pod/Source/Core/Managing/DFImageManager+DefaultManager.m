// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFCompositeImageManager.h"
#import "DFImageCache.h"
#import "DFImageManager.h"
#import "DFImageManagerConfiguration.h"
#import "DFImageProcessor.h"

#if __has_include("DFImageManagerKit+AFNetworking.h")
#import "DFImageManagerKit+AFNetworking.h"
#import <AFNetworking/AFHTTPSessionManager.h>
#endif

#if __has_include("DFImageManagerKit+NSURLSession.h")
#import "DFImageManagerKit+NSURLSession.h"
#endif

#if __has_include("DFImageManagerKit+PhotosKit.h")
#import "DFImageManagerKit+PhotosKit.h"
#endif

@implementation DFImageManager (DefaultManager)

+ (nonnull id<DFImageManaging>)createDefaultManager {
    NSMutableArray *managers = [NSMutableArray new];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-variable"
    DFImageProcessor *processor = [DFImageProcessor new];
    DFImageCache *cache = [DFImageCache new];
#pragma clang diagnostic pop
    
#if __has_include("DFImageManagerKit+AFNetworking.h")
    [managers addObject:({
        AFHTTPSessionManager *httpSessionManager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:[self _defaultSessionConfiguration]];
        httpSessionManager.responseSerializer = [AFHTTPResponseSerializer new];
        DFAFImageFetcher *fetcher = [[DFAFImageFetcher alloc] initWithSessionManager:httpSessionManager];
        [[DFImageManager alloc] initWithConfiguration:[DFImageManagerConfiguration configurationWithFetcher:fetcher processor:processor cache:cache]];
    })];
#elif __has_include("DFImageManagerKit+NSURLSession.h")
    [managers addObject:({
        DFURLImageFetcher *fetcher = [[DFURLImageFetcher alloc] initWithSessionConfiguration:[self _defaultSessionConfiguration]];
        [[DFImageManager alloc] initWithConfiguration:[DFImageManagerConfiguration configurationWithFetcher:fetcher processor:processor cache:cache]];
    })];
#endif
    
#if __has_include("DFImageManagerKit+PhotosKit.h")
    [managers addObject:({
        DFPhotosKitImageFetcher *fetcher = [DFPhotosKitImageFetcher new];
        [[DFImageManager alloc] initWithConfiguration:[DFImageManagerConfiguration configurationWithFetcher:fetcher processor:processor cache:cache]];
    })];
#endif
    
    return [[DFCompositeImageManager alloc] initWithImageManagers:managers];
}

+ (NSURLSessionConfiguration *)_defaultSessionConfiguration {
    NSURLSessionConfiguration *conf = [NSURLSessionConfiguration defaultSessionConfiguration];
    conf.URLCache = [[NSURLCache alloc] initWithMemoryCapacity:0 diskCapacity:1024 * 1024 * 200 diskPath:@"com.github.kean.default_image_cache"];
    conf.timeoutIntervalForRequest = 60.f;
    conf.timeoutIntervalForResource = 360.f;
    return conf;
}

@end
