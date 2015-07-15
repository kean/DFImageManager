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

#import "DFCompositeImageManager.h"
#import "DFImageRequest.h"
#import "DFImageTask.h"

#define DFManagerForRequest(request) \
({ \
    id<DFImageManaging> outManager_macro; \
    for (id<DFImageManaging> manager_macro in _managers) { \
        if ([manager_macro canHandleRequest:request]) { \
            outManager_macro = manager_macro; \
            break; \
        } \
    } \
    outManager_macro; \
})

@implementation DFCompositeImageManager {
    NSMutableArray /* id<DFImageManaging> */ *_managers;
}

- (instancetype)initWithImageManagers:(NSArray *)imageManagers {
    if (self = [super init]) {
        _managers = [NSMutableArray arrayWithArray:imageManagers];
    }
    return self;
}

- (void)addImageManager:(id<DFImageManaging>)imageManager {
    [self addImageManagers:@[imageManager]];
}

- (void)addImageManagers:(NSArray *)imageManagers {
    [_managers addObjectsFromArray:imageManagers];
}

- (void)removeImageManager:(id<DFImageManaging>)imageManager {
    [self removeImageManagers:@[imageManager]];
}

- (void)removeImageManagers:(NSArray *)imageManagers {
    [_managers removeObjectsInArray:imageManagers];
}

#pragma mark - <DFImageManaging>

- (BOOL)canHandleRequest:(DFImageRequest *)request {
    return DFManagerForRequest(request) != nil;
}

- (DFImageTask *)imageTaskForResource:(id)resource completion:(DFImageRequestCompletion)completion {
    return [self imageTaskForRequest:[DFImageRequest requestWithResource:resource] completion:completion];
}

- (DFImageTask *)imageTaskForRequest:(DFImageRequest *)request completion:(DFImageRequestCompletion)completion {
    id<DFImageManaging> manager = DFManagerForRequest(request);
    if (!manager) {
        [NSException raise:NSInvalidArgumentException format:@"There are no managers that can handle the request %@", request];
    }
    return [manager imageTaskForRequest:request completion:completion];
}

- (void)getImageTasksWithCompletion:(void (^)(NSArray *, NSArray *))completion {
    NSMutableArray *allTasks = [NSMutableArray new];
    NSMutableArray *allPreheatingTasks = [NSMutableArray new];
    NSInteger __block numberOfCallbacks = 0;
    for (id<DFImageManaging> manager in _managers) {
        [manager getImageTasksWithCompletion:^(NSArray *tasks, NSArray *preheatingTasks) {
            [allTasks addObjectsFromArray:tasks];
            [allPreheatingTasks addObjectsFromArray:preheatingTasks];
            numberOfCallbacks++;
            if (numberOfCallbacks == _managers.count) {
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

- (void)startPreheatingImagesForRequests:(NSArray *)requests {
    for (DFImageRequest *request in requests) {
        [DFManagerForRequest(request) startPreheatingImagesForRequests:@[request]];
    }
}

- (void)stopPreheatingImagesForRequests:(NSArray *)requests {
    for (DFImageRequest *request in requests) {
        [DFManagerForRequest(request) stopPreheatingImagesForRequests:@[request]];
    }
}

- (void)stopPreheatingImagesForAllRequests {
    for (id<DFImageManaging> manager in _managers) {
        [manager stopPreheatingImagesForAllRequests];
    }
}

#pragma mark - Deprecated

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

- (DFImageTask *)requestImageForResource:(id)resource completion:(DFImageRequestCompletion)completion {
    return [self requestImageForRequest:[DFImageRequest requestWithResource:resource] completion:completion];
}

- (DFImageTask *)requestImageForRequest:(DFImageRequest *)request completion:(DFImageRequestCompletion)completion {
    DFImageTask *task = [self imageTaskForRequest:request completion:completion];
    [task resume];
    return task;
}

#pragma clang diagnostic pop

@end
