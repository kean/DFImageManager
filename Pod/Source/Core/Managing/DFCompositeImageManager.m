// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFCompositeImageManager.h"
#import "DFImageRequest.h"

#define DFManagerForRequest(request) ({ \
    id<DFImageManaging> __df_outManager; \
    for (id<DFImageManaging> __df_manager in _managers) { \
        if ([__df_manager canHandleRequest:request]) { \
            __df_outManager = __df_manager; \
            break; \
        } \
    } \
    __df_outManager; })

@implementation DFCompositeImageManager {
    NSMutableArray<id<DFImageManaging>> *_managers;
}

- (nonnull instancetype)initWithImageManagers:(nonnull NSArray<id<DFImageManaging>> *)imageManagers {
    if (self = [super init]) {
        _managers = [NSMutableArray arrayWithArray:imageManagers];
    }
    return self;
}

- (nonnull instancetype)init {
    return [self initWithImageManagers:@[]];
}

- (void)addImageManager:(nonnull id<DFImageManaging>)imageManager {
    [_managers addObject:imageManager];
}

- (void)removeImageManager:(nonnull id<DFImageManaging>)imageManager {
    [_managers removeObject:imageManager];
}

#pragma mark <DFImageManaging>

- (BOOL)canHandleRequest:(nonnull DFImageRequest *)request {
    return DFManagerForRequest(request) != nil;
}

- (nonnull DFImageTask *)imageTaskForResource:(nonnull id)resource completion:(nullable DFImageTaskCompletion)completion {
    return [self imageTaskForRequest:[DFImageRequest requestWithResource:resource] completion:completion];
}

- (nonnull DFImageTask *)imageTaskForRequest:(nonnull DFImageRequest *)request completion:(nullable DFImageTaskCompletion)completion {
    id<DFImageManaging> manager = DFManagerForRequest(request);
    if (!manager) {
        [NSException raise:NSInvalidArgumentException format:@"There are no managers that can handle the request %@", request];
    }
    return [manager imageTaskForRequest:request completion:completion];
}

- (void)getImageTasksWithCompletion:(void (^ __nullable)(NSArray<DFImageTask *> * __nonnull, NSArray<DFImageTask *> * __nonnull))completion {
    NSMutableArray *allTasks = [NSMutableArray new];
    NSMutableArray *allPreheatingTasks = [NSMutableArray new];
    NSInteger __block numberOfCallbacks = (NSInteger)_managers.count;
    for (id<DFImageManaging> manager in _managers) {
        [manager getImageTasksWithCompletion:^(NSArray *tasks, NSArray *preheatingTasks) {
            [allTasks addObjectsFromArray:tasks];
            [allPreheatingTasks addObjectsFromArray:preheatingTasks];
            numberOfCallbacks--;
            if (numberOfCallbacks == 0) {
                completion(allTasks, allPreheatingTasks);
            }
        }];
    }
}

- (void)invalidateAndCancel {
    for (id<DFImageManaging> manager in _managers) {
        [manager invalidateAndCancel];
    }
}

- (void)startPreheatingImagesForRequests:(nonnull NSArray *)requests {
    NSMapTable *table = [self _dispatchTableForRequests:requests];
    for (id<DFImageManaging> manager in table) {
        [manager startPreheatingImagesForRequests:[table objectForKey:manager]];
    }
}

- (void)stopPreheatingImagesForRequests:(nonnull NSArray *)requests {
    NSMapTable *table = [self _dispatchTableForRequests:requests];
    for (id<DFImageManaging> manager in table) {
        [manager stopPreheatingImagesForRequests:[table objectForKey:manager]];
    }
}

- (nonnull NSMapTable *)_dispatchTableForRequests:(nonnull NSArray *)inputRequests {
    id<DFImageManaging> manager;
    NSMutableArray *requests;
    NSMapTable *table = [NSMapTable strongToStrongObjectsMapTable];
    for (DFImageRequest *request in inputRequests) {
        if (![manager canHandleRequest:request]) {
            manager = DFManagerForRequest(request);
            if (!manager) {
                [NSException raise:NSInvalidArgumentException format:@"There are no managers that can handle the request %@", request];
            }
            requests = [table objectForKey:manager];
            if (!requests) {
                requests = [NSMutableArray new];
                [table setObject:requests forKey:manager];
            }
        }
        [requests addObject:request];
    }
    return table;
}

- (void)stopPreheatingImagesForAllRequests {
    for (id<DFImageManaging> manager in _managers) {
        [manager stopPreheatingImagesForAllRequests];
    }
}

- (void)removeAllCachedImages {
    for (id<DFImageManaging> manager in _managers) {
        [manager removeAllCachedImages];
    }
}

@end
