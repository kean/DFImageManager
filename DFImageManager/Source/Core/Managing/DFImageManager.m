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

@protocol _DFImageTaskManaging

- (void)resumeManagedTask:(nonnull _DFImageTask *)task;
- (void)cancelManagedTask:(nonnull _DFImageTask *)task;
- (void)managedTaskDidChangePriority:(nonnull _DFImageTask *)task;
- (nonnull NSProgress *)progressForManagedTask:(nonnull _DFImageTask *)task;

@end

@interface _DFImageTask : DFImageTask

@property (nonnull, nonatomic, readonly) id<_DFImageTaskManaging> manager;
@property (nonatomic) DFImageTaskState state;
@property (nullable, atomic) NSProgress *internalProgress;
@property (nullable, atomic) UIImage *image;
@property (nullable, atomic) NSError *error;
@property (nullable, atomic) DFImageResponse *response;
@property (nonatomic) NSInteger tag;
@property (nonatomic) BOOL preheating;

@end

@implementation _DFImageTask

@synthesize completionHandler = _completionHandler;
@synthesize request = _request;
@synthesize priority = _priority;
@synthesize error = _error;
@synthesize response = _response;
@synthesize state = _state;

- (instancetype)initWithManager:(nonnull id<_DFImageTaskManaging>)manager request:(nonnull DFImageRequest *)request completionHandler:(nullable DFImageTaskCompletion)completionHandler {
    if (self = [super init]) {
        _manager = manager;
        _request = request;
        _priority = request.options.priority;
        _completionHandler = completionHandler;
        _state = DFImageTaskStateSuspended;
    }
    return self;
}

- (void)resume {
    [self.manager resumeManagedTask:self];
}

- (void)cancel {
    [self.manager cancelManagedTask:self];
}

- (void)setPriority:(DFImageRequestPriority)priority {
    if (_priority != priority) {
        _priority = priority;
        [self.manager managedTaskDidChangePriority:self];
    }
}

- (NSProgress * __nonnull)progress {
    return [self.manager progressForManagedTask:self];
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

@interface DFImageManager () <NSLocking, _DFImageTaskManaging, DFImageManagerImageLoaderDelegate>

@property (nonnull, nonatomic, readonly) DFImageManagerImageLoader *imageLoader;
@property (nonnull, nonatomic, readonly) NSMutableSet /* _DFImageTask */ *executingImageTasks;
@property (nonnull, nonatomic, readonly) NSMutableDictionary /* _DFImageCacheKey : _DFImageTask */ *preheatingTasks;
@property (nonnull, nonatomic, readonly) NSRecursiveLock *recursiveLock;

@end

@implementation DFImageManager {
    NSInteger _preheatingTaskCounter;
    BOOL _invalidated;
    BOOL _needsToExecutePreheatingTasks;
}

@synthesize configuration = _conf;

DF_INIT_UNAVAILABLE_IMPL

- (nonnull instancetype)initWithConfiguration:(nonnull DFImageManagerConfiguration *)configuration {
    if (self = [super init]) {
        NSParameterAssert(configuration);
        _conf = [configuration copy];
        _imageLoader = [[DFImageManagerImageLoader alloc] initWithConfiguration:configuration];
        _imageLoader.delegate = self;
        _preheatingTasks = [NSMutableDictionary new];
        _executingImageTasks = [NSMutableSet new];
        _recursiveLock = [NSRecursiveLock new];
    }
    return self;
}

+ (void)initialize {
    [self setSharedManager:[self createDefaultManager]];
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
        completion(tasks.allObjects, preheatingTasks.allObjects);
    });
}

- (void)invalidateAndCancel {
    [self lock];
    if (_invalidated) {
        return;
    }
    _invalidated = YES;
    [_preheatingTasks removeAllObjects];
    _imageLoader.delegate = nil;
    for (_DFImageTask *task in _executingImageTasks) {
        [self _setImageTaskState:DFImageTaskStateCancelled task:task];
    }
    [self unlock];
}

- (void)removeAllCachedImages {
    [_conf.cache removeAllObjects];
    if ([_conf.fetcher respondsToSelector:@selector(removeAllCachedImages)]) {
        [_conf.fetcher removeAllCachedImages];
    }
}

#pragma mark <DFImageManaging> (Preheating)

- (void)startPreheatingImagesForRequests:(nonnull NSArray *)requests {
    if (_invalidated) {
        return;
    }
    requests = [_imageLoader canonicalRequestsForRequests:requests];
    [self lock];
    for (DFImageRequest *request in requests) {
        id<NSCopying> key = [_imageLoader processingKeyForRequest:request];
        if (!_preheatingTasks[key]) {
            _DFImageTask *task = [[_DFImageTask alloc] initWithManager:self request:request completionHandler:nil];
            task.preheating = YES;
            task.tag = _preheatingTaskCounter++;
            _preheatingTasks[key] = task;
        }
    }
    [self _setNeedsExecutePreheatingTasks];
    [self unlock];
}

- (void)stopPreheatingImagesForRequests:(nonnull NSArray *)requests {
    requests = [_imageLoader canonicalRequestsForRequests:requests];
    [self lock];
    for (DFImageRequest *request in requests) {
        id<NSCopying> key = [_imageLoader processingKeyForRequest:request];
        _DFImageTask *task = _preheatingTasks[key];
        if (task) {
            [self _setImageTaskState:DFImageTaskStateCancelled task:task];
        }
    }
    [self unlock];
}

- (void)stopPreheatingImagesForAllRequests {
    [self lock];
    for (_DFImageTask *task in _preheatingTasks.allValues) {
        [self _setImageTaskState:DFImageTaskStateCancelled task:task];
    }
    [self unlock];
}

- (void)_setNeedsExecutePreheatingTasks {
    if (!_needsToExecutePreheatingTasks && !_invalidated) {
        _needsToExecutePreheatingTasks = YES;
        // Manager won't start executing preheating tasks in case you are about to add normal (non-preheating) right after adding preheating ones.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self lock];
            [self _executePreheatingTasksIfNeeded];
            [self unlock];
        });
    }
}

- (void)_executePreheatingTasksIfNeeded {
    _needsToExecutePreheatingTasks = NO;
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

- (void)_imageTaskDidComplete:(_DFImageTask *)task {
    if (_preheatingTasks.count) {
        if (task.preheating || !task.error) {
            [_preheatingTasks removeObjectForKey:[_imageLoader processingKeyForRequest:task.request]];
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
        [_imageLoader cancelLoadingForImageTask:task];
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
        [_imageLoader startLoadingForImageTask:task];
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
        DFDispatchAsync(^{
            DFImageTaskCompletion completion = task.completionHandler;
            if (completion) {
                completion(task.image, task.error, task.response, task);
                task.image = nil;
            }
        });
        [self _imageTaskDidComplete:task];
    }
}

#pragma mark - <DFImageManagerImageLoaderDelegate>

- (void)imageLoader:(nonnull DFImageManagerImageLoader *)imageLoader imageTask:(nonnull _DFImageTask *)task didUpdateProgressWithCompletedUnitCount:(int64_t)completedUnitCount totalUnitCount:(int64_t)totalUnitCount {
    NSProgress *progress = task.internalProgress;
    progress.totalUnitCount = totalUnitCount;
    progress.completedUnitCount = completedUnitCount;
}

- (void)imageLoader:(nonnull DFImageManagerImageLoader *)imageLoader imageTask:(nonnull DFImageTask *)task didReceiveProgressiveImage:(nonnull UIImage *)image {
    dispatch_async(dispatch_get_main_queue(), ^{
        void (^handler)(UIImage *__nonnull) = task.progressiveImageHandler;
        if (handler) {
            handler(image);
        }
    });
}

- (void)imageLoader:(nonnull DFImageManagerImageLoader *)imageLoader imageTask:(nonnull _DFImageTask *)task didCompleteWithImage:(nullable UIImage *)image info:(nullable NSDictionary *)info error:(nullable NSError *)error {
    task.image = image;
    task.response = [[DFImageResponse alloc] initWithInfo:info isFastResponse:NO];
    task.error = error;
    
    [self lock];
    [self _setImageTaskState:DFImageTaskStateCompleted task:task];
    [self unlock];
}

#pragma mark <NSLocking>

- (void)lock {
    [_recursiveLock lock];
}

- (void)unlock {
    [_recursiveLock unlock];
}

#pragma mark - <_DFImageTaskManaging>

- (void)resumeManagedTask:(nonnull _DFImageTask *)task {
    if (_invalidated) {
        return;
    }
    [self lock];
    [self _setImageTaskState:DFImageTaskStateRunning task:task];
    [self unlock];
}

- (void)cancelManagedTask:(nonnull _DFImageTask *)task {
    if (_invalidated) {
        return;
    }
    [self lock];
    [self _setImageTaskState:DFImageTaskStateCancelled task:task];
    [self unlock];
}

- (void)managedTaskDidChangePriority:(nonnull _DFImageTask *)task {
    if (_invalidated) {
        return;
    }
    [self lock];
    [_imageLoader updateLoadingPriorityForImageTask:task];
    [self unlock];
}

- (NSProgress *)progressForManagedTask:(nonnull _DFImageTask *)task {
    [self lock];
    NSProgress *progress = task.internalProgress;
    if (!progress) {
        progress = [NSProgress progressWithTotalUnitCount:-1];
        _DFImageTask *__weak weakTask = task;
        progress.cancellationHandler = ^{
            [weakTask cancel];
        };
        task.internalProgress = progress;
    }
    [self unlock];
    return progress;
}

#pragma mark Support

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %p> { name = %@ }", [self class], self, self.name];
}

@end
