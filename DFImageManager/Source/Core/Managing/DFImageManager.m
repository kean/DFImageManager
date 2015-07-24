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
#import "DFImageCaching.h"
#import "DFImageFetching.h"
#import "DFImageManager.h"
#import "DFImageManagerConfiguration.h"
#import "DFImageManagerDefines.h"
#import "DFImageManagerImageLoader.h"
#import "DFImageProcessing.h"
#import "DFImageRequest.h"
#import "DFImageRequestOptions.h"
#import "DFImageResponse.h"
#import "DFImageTask.h"

#pragma mark - _DFImageTask

@class _DFImageTask;

@interface DFImageManager (_DFImageTask)

- (void)resumeTask:(nonnull _DFImageTask *)task;
- (void)cancelTask:(nonnull _DFImageTask *)task;
- (void)setPriority:(DFImageRequestPriority)priority forTask:(nonnull _DFImageTask *)task;

@end

@interface _DFImageTask : DFImageTask

@property (nonnull, nonatomic, readonly) DFImageManager *manager;
@property (nonatomic) DFImageTaskState state;
@property (nullable, atomic) UIImage *image;
@property (nullable, atomic) NSError *error;
@property (nullable, atomic) DFImageResponse *response;
@property (nonatomic) NSInteger tag;
@property (nonatomic) BOOL preheating;
@property (nullable, nonatomic, weak) DFImageManagerImageLoaderTask *loadTask;

@end

@implementation _DFImageTask

@synthesize completionHandler = _completionHandler;
@synthesize request = _request;
@synthesize error = _error;
@synthesize response = _response;
@synthesize state = _state;
@synthesize progress = _progress;

- (instancetype)initWithManager:(nonnull DFImageManager *)manager request:(nonnull DFImageRequest *)request completionHandler:(nullable DFImageTaskCompletion)completionHandler {
    if (self = [super init]) {
        _manager = manager;
        _request = request;
        _completionHandler = completionHandler;
        _state = DFImageTaskStateSuspended;
        
        _progress = [NSProgress progressWithTotalUnitCount:-1];
        _DFImageTask *__weak weakSelf = self;
        _progress.cancellationHandler = ^{
            [weakSelf cancel];
        };
    }
    return self;
}

- (void)resume {
    [self.manager resumeTask:self];
}

- (void)cancel {
    [self.manager cancelTask:self];
}

- (void)setPriority:(DFImageRequestPriority)priority {
    [self.manager setPriority:priority forTask:self];
}

- (BOOL)isValidNextState:(DFImageTaskState)nextState {
    switch (self.state) {
        case DFImageTaskStateSuspended:
            return (nextState == DFImageTaskStateRunning ||
                    nextState == DFImageTaskStateCancelled);
        case DFImageTaskStateRunning:
            return (nextState == DFImageTaskStateCompleted ||
                    nextState == DFImageTaskStateCancelled);
        default:
            return NO;
    }
}

@end


#pragma mark - DFImageManager

static inline void DFDispatchAsync(dispatch_block_t block) {
    ([NSThread isMainThread]) ? block() : dispatch_async(dispatch_get_main_queue(), block);
}

@interface DFImageManager () <NSLocking>

@property (nonnull, nonatomic, readonly) DFImageManagerImageLoader *imageLoader;
@property (nonnull, nonatomic, readonly) NSMutableSet /* _DFImageTask */ *executingImageTasks;
@property (nonnull, nonatomic, readonly) NSMutableDictionary /* _DFImageCacheKey : _DFImageTask */ *preheatingTasks;
@property (nonnull, nonatomic, readonly) NSRecursiveLock *recursiveLock;

@end

@implementation DFImageManager {
    NSInteger _preheatingTaskCounter;
    BOOL _invalidated;
    BOOL _needsToExecutePreheatTasks;
}

@synthesize configuration = _conf;

- (nonnull instancetype)initWithConfiguration:(nonnull DFImageManagerConfiguration *)configuration {
    if (self = [super init]) {
        NSParameterAssert(configuration);
        _conf = [configuration copy];
        _imageLoader = [[DFImageManagerImageLoader alloc] initWithFetcher:_conf.fetcher cache:_conf.cache processor:_conf.processor processingQueue:_conf.processingQueue];
        _preheatingTasks = [NSMutableDictionary new];
        _executingImageTasks = [NSMutableSet new];
        _recursiveLock = [NSRecursiveLock new];
    }
    return self;
}

#pragma mark <DFImageManaging>

- (BOOL)canHandleRequest:(nonnull DFImageRequest *)request {
    NSParameterAssert(request);
    return [_conf.fetcher canHandleRequest:request];
}

- (nullable DFImageTask *)imageTaskForResource:(nonnull id)resource completion:(nullable DFImageTaskCompletion)completion {
    NSParameterAssert(resource);
    return [self imageTaskForRequest:[DFImageRequest requestWithResource:resource] completion:completion];
}

- (nullable DFImageTask *)imageTaskForRequest:(nonnull DFImageRequest *)request completion:(nullable DFImageTaskCompletion)completion {
    NSParameterAssert(request);
    if (_invalidated) {
        return nil;
    }
    return [[_DFImageTask alloc] initWithManager:self request:[_imageLoader canonicalRequestForRequest:request] completionHandler:completion];
}

- (void)getImageTasksWithCompletion:(void (^ __nullable)(NSArray * __nonnull, NSArray * __nonnull))completion {
    NSMutableSet *tasks = [NSMutableSet new];
    NSMutableSet *preheatingTasks = [NSMutableSet new];
    [self lock];
    for (_DFImageTask *task in _executingImageTasks) {
        if (task.preheating) {
            [preheatingTasks addObject:task];
        } else {
            [tasks addObject:task];
        }
    }
    for (_DFImageTask *task in _preheatingTasks.allValues) {
        [preheatingTasks addObject:task];
    }
    [self unlock];
    dispatch_async(dispatch_get_main_queue(), ^{
        completion([tasks allObjects], [preheatingTasks allObjects]);
    });
}

- (void)invalidateAndCancel {
    [self lock];
    if (!_invalidated) {
        _invalidated = YES;
        [_preheatingTasks removeAllObjects];
        for (_DFImageTask *task in _executingImageTasks) {
            [self _setImageTaskState:DFImageTaskStateCancelled task:task];
        }
    }
    [self unlock];
}

#pragma mark <DFImageManaging> (Preheating)

- (void)startPreheatingImagesForRequests:(nonnull NSArray *)requests {
    if (_invalidated) {
        return;
    }
    for (DFImageRequest *request in [self _canonicalRequestsForRequests:requests]) {
        id<NSCopying> key = [_imageLoader processingKeyForRequest:request];
        [self lock];
        if (!_preheatingTasks[key]) {
            DFImageManager *__weak weakSelf = self;
            _DFImageTask *task = [[_DFImageTask alloc] initWithManager:self request:request completionHandler:^(UIImage *__nullable image, NSError *__nullable error, DFImageResponse *__nullable response, DFImageTask *__nonnull completedTask) {
                DFImageManager *strongSelf = weakSelf;
                if (strongSelf) {
                    [strongSelf lock];
                    [strongSelf.preheatingTasks removeObjectForKey:key];
                    [strongSelf unlock];
                }
            }];
            task.preheating = YES;
            task.tag = _preheatingTaskCounter++;
            _preheatingTasks[key] = task;
        }
        [self unlock];
    }
    [self lock];
    [self _setNeedsExecutePreheatingTasks];
    [self unlock];
}

- (void)stopPreheatingImagesForRequests:(nonnull NSArray *)requests {
    for (DFImageRequest *request in [self _canonicalRequestsForRequests:requests]) {
        id<NSCopying> key = [_imageLoader processingKeyForRequest:request];
        [self lock];
        _DFImageTask *task = _preheatingTasks[key];
        if (task) {
            [self _setImageTaskState:DFImageTaskStateCancelled task:task];
            [_preheatingTasks removeObjectForKey:key];
        }
        [self unlock];
    }
}

- (void)stopPreheatingImagesForAllRequests {
    [self lock];
    for (_DFImageTask *task in _preheatingTasks.allValues) {
        [self _setImageTaskState:DFImageTaskStateCancelled task:task];
    }
    [_preheatingTasks removeAllObjects];
    [self unlock];
}

- (void)_setNeedsExecutePreheatingTasks {
    if (!_needsToExecutePreheatTasks && !_invalidated) {
        _needsToExecutePreheatTasks = YES;
        // Manager won't start executing preheating tasks in case you are about to add normal (non-preheating) right after adding preheating ones.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self lock];
            [self _executePreheatingTasksIfNeeded];
            [self unlock];
        });
    }
}

- (void)_executePreheatingTasksIfNeeded {
    _needsToExecutePreheatTasks = NO;
    NSUInteger executingTaskCount = _executingImageTasks.count;
    if (executingTaskCount < _conf.maximumConcurrentPreheatingRequests) {
        for (_DFImageTask *task in [_preheatingTasks.allValues sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"tag" ascending:YES]]]) {
            if (executingTaskCount >= _conf.maximumConcurrentPreheatingRequests) {
                return;
            }
            if (task.state == DFImageTaskStateSuspended) {
                [self _setImageTaskState:DFImageTaskStateRunning task:task];
                executingTaskCount++;
            }
        }
    }
}

#pragma mark FSM (DFImageTaskState)

- (void)_setImageTaskState:(DFImageTaskState)state task:(nonnull _DFImageTask *)task {
    if ([task isValidNextState:state]) {
        [self _transitionActionFromState:task.state toState:state task:task];
        task.state = state;
        [self _enterActionForState:state task:task];
    }
}

- (void)_transitionActionFromState:(DFImageTaskState)fromState toState:(DFImageTaskState)toState task:(nonnull _DFImageTask *)task {
    if (fromState == DFImageTaskStateRunning && toState == DFImageTaskStateCancelled) {
        [_imageLoader cancelTask:task.loadTask];
    }
}

- (void)_enterActionForState:(DFImageTaskState)state task:(nonnull _DFImageTask *)task {
    if (state == DFImageTaskStateRunning) {
        DFCachedImageResponse *response = [_imageLoader cachedResponseForRequest:task.request];
        if (response) { // fast path
            task.image = response.image;
            task.response = [[DFImageResponse alloc] initWithInfo:response.info isFastResponse:YES];
            [self _setImageTaskState:DFImageTaskStateCompleted task:task];
            return;
        }
        [_executingImageTasks addObject:task];
        DFImageManager *__weak weakSelf = self;
        task.loadTask = [_imageLoader startTaskForRequest:task.request progressHandler:^(int64_t completedUnitCount, int64_t totalUnitCount) {
            task.progress.totalUnitCount = totalUnitCount;
            task.progress.completedUnitCount = completedUnitCount;
        } completion:^(UIImage *__nullable image, NSDictionary *__nullable info, NSError *__nullable error) {
            task.loadTask = nil;
            task.image = image;
            task.response = [[DFImageResponse alloc] initWithInfo:info isFastResponse:NO];
            task.error = error;
            DFImageManager *strongSelf = weakSelf;
            if (strongSelf) {
                [strongSelf lock];
                [strongSelf _setImageTaskState:DFImageTaskStateCompleted task:task];
                [strongSelf unlock];
            }
        }];
    }
    if (state == DFImageTaskStateCompleted || state == DFImageTaskStateCancelled) {
        [_executingImageTasks removeObject:task];
        [self _setNeedsExecutePreheatingTasks];
        
        if (state == DFImageTaskStateCancelled) {
            task.error = [NSError errorWithDomain:DFImageManagerErrorDomain code:DFImageManagerErrorCancelled userInfo:nil];
        }
        if (state == DFImageTaskStateCompleted) {
            if (!task.image && !task.error) {
                task.error = [NSError errorWithDomain:DFImageManagerErrorDomain code:DFImageManagerErrorUnknown userInfo:nil];
            }
        }
        DFImageTaskCompletion completion = task.completionHandler;
        if (completion) {
            DFDispatchAsync(^{
                completion(task.image, task.error, task.response, task);
                task.image = nil;
            });
        }
    }
}

#pragma mark <NSLocking>

- (void)lock {
    [_recursiveLock lock];
}

- (void)unlock {
    [_recursiveLock unlock];
}

#pragma mark Support

- (nonnull NSArray *)_canonicalRequestsForRequests:(nonnull NSArray *)requests {
    NSMutableArray *canonicalRequests = [[NSMutableArray alloc] initWithCapacity:requests.count];
    for (DFImageRequest *request in requests) {
        [canonicalRequests addObject:[_imageLoader canonicalRequestForRequest:request]];
    }
    return canonicalRequests;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %p> { name = %@ }", [self class], self, self.name];
}

#pragma mark - Deprecated

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

- (nullable DFImageTask *)requestImageForResource:(id __nonnull)resource completion:(nullable DFImageTaskCompletion)completion {
    return [self requestImageForRequest:[DFImageRequest requestWithResource:resource] completion:completion];
}

- (nullable DFImageTask *)requestImageForRequest:(DFImageRequest * __nonnull)request completion:(nullable DFImageTaskCompletion)completion {
    DFImageTask *task = [self imageTaskForRequest:request completion:completion];
    [task resume];
    return task;
}

#pragma clang diagnostic pop

@end


@implementation DFImageManager (_DFImageTask)

- (void)resumeTask:(nonnull _DFImageTask *)task {
    if (_invalidated) {
        return;
    }
    [self lock];
    [self _setImageTaskState:DFImageTaskStateRunning task:task];
    [self unlock];
}

- (void)cancelTask:(nonnull _DFImageTask *)task {
    if (_invalidated) {
        return;
    }
    [self lock];
    [self _setImageTaskState:DFImageTaskStateCancelled task:task];
    [self unlock];
}

- (void)setPriority:(DFImageRequestPriority)priority forTask:(nonnull _DFImageTask *)task {
    if (_invalidated) {
        return;
    }
    [self lock];
    if (task.request.options.priority != priority) {
        task.request.options.priority = priority;
        [_imageLoader updatePriorityForTask:task.loadTask];
    }
    [self unlock];
}

@end
