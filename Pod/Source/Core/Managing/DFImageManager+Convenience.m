// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFImageManager.h"

@implementation DFImageManager (Convenience)

+ (DFImageTask *)imageTaskForResource:(id)resource completion:(DFImageTaskCompletion)completion {
    return [[self sharedManager] imageTaskForResource:resource completion:completion];
}

+ (DFImageTask *)imageTaskForRequest:(DFImageRequest *)request completion:(DFImageTaskCompletion)completion {
    return [[self sharedManager] imageTaskForRequest:request completion:completion];
}

+ (void)getImageTasksWithCompletion:(void (^)(NSArray<DFImageTask *> * _Nonnull, NSArray<DFImageTask *> * _Nonnull))completion {
    [[self sharedManager] getImageTasksWithCompletion:completion];
}

+ (void)invalidateAndCancel {
    [[self sharedManager] invalidateAndCancel];
}

+ (void)startPreheatingImagesForRequests:(NSArray<DFImageRequest *> *)requests {
    [[self sharedManager] startPreheatingImagesForRequests:requests];
}

+ (void)stopPreheatingImagesForRequests:(NSArray<DFImageRequest *> *)requests {
    [[self sharedManager] stopPreheatingImagesForRequests:requests];
}

+ (void)stopPreheatingImagesForAllRequests {
    [[self sharedManager] stopPreheatingImagesForAllRequests];
}

+ (void)removeAllCachedImages {
    [[self sharedManager] removeAllCachedImages];
}

@end
