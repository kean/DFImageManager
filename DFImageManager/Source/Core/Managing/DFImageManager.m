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
@property (nullable, nonatomic) NSError *error;
@property (nullable, nonatomic) DFImageResponse *response;
@property (nonatomic) NSInteger tag;
@property (nonatomic) BOOL preheating;
@property (nullable, nonatomic, weak) DFImageManagerImageLoaderTask *loadTask;

@end

@implementation _DFImageTask

@synthesize completionHandler = _completionHandler;
@synthesize request = _request;
@synthesize error = _error;
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

@interface DFImageManager () <NSLocking>
@end

@implementation DFImageManager {
    DFImageManagerImageLoader *_imageLoder;
    NSMutableSet /* _DFImageTask */ *_executingImageTasks;
    NSMutableDictionary /* _DFImageCacheKey : _DFImageTask */ *_preheatingTasks;
    NSInteger _preheatingTaskCounter;
    BOOL _invalidated;
    BOOL _needsToExecutePreheatTasks;
    NSRecursiveLock *_lock;
}

@synthesize configuration = _conf;

- (nonnull instancetype)initWithConfiguration:(nonnull DFImageManagerConfiguration *)configuration {
    if (self = [super init]) {
        NSParameterAssert(configuration);
        _conf = [configuration copy];
        _imageLoder = [[DFImageManagerImageLoader alloc] initWithFetcher:_conf.fetcher cache:_conf.cache processor:_conf.processor processingQueue:_conf.processingQueue];
        _preheatingTasks = [NSMutableDictionary new];
        _executingImageTasks = [NSMutableSet new];
        _lock = [NSRecursiveLock new];
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
    return [[_DFImageTask alloc] initWithManager:self request:[_imageLoder canonicalRequestForRequest:request] completionHandler:completion];
}

- (void)_resumeImageTask:(nonnull _DFImageTask *)task {
    if (_invalidated) {
        return;
    }
    if ([NSThread isMainThread]) {
        DFImageResponse *response = [_imageLoder cachedResponseForRequest:task.request];
        if (response.image) {
            task.state = DFImageTaskStateCompleted;
            DFImageTaskCompletion completion = task.completionHandler;
            if (completion) {
                NSMutableDictionary *info = [self _infoFromResponse:response task:task];
                info[DFImageInfoIsFromMemoryCacheKey] = @YES;
                completion(response.image, info);
            }
            return;
        }
    }
    [self lock];
    [self _setImageTaskState:DFImageTaskStateRunning task:task];
    [self unlock];
    
}

- (void)_setImageTaskState:(DFImageTaskState)state task:(nonnull _DFImageTask *)task {
    if ([task isValidNextState:state]) {
        [self _transitionActionFromState:task.state toState:state task:task];
        task.state = state;
        [self _enterActionForState:state task:task];
    }
}

- (void)_transitionActionFromState:(DFImageTaskState)fromState toState:(DFImageTaskState)toState task:(nonnull _DFImageTask *)task {
    if (fromState == DFImageTaskStateRunning && toState == DFImageTaskStateCancelled) {
        [_imageLoder cancelTask:task.loadTask];
    }
}

- (void)_enterActionForState:(DFImageTaskState)state task:(nonnull _DFImageTask *)task {
    if (state == DFImageTaskStateRunning) {
        [_executingImageTasks addObject:task];
        
        DFImageManager *__weak weakSelf = self;
        task.loadTask = [_imageLoder startTaskForRequest:task.request progressHandler:^(int64_t completedUnitCount, int64_t totalUnitCount) {
            task.progress.totalUnitCount = totalUnitCount;
            task.progress.completedUnitCount = completedUnitCount;
        } completion:^(DFImageResponse * __nullable response) {
            task.loadTask = nil;
            task.response = response;
            [weakSelf lock];
            [weakSelf _setImageTaskState:DFImageTaskStateCompleted task:task];
            [weakSelf unlock];
        }];
    }
    if (state == DFImageTaskStateCompleted || state == DFImageTaskStateCancelled) {
        [_executingImageTasks removeObject:task];
        [self _setNeedsExecutePreheatingTasks];
        
        if (state == DFImageTaskStateCancelled) {
            NSError *error = [NSError errorWithDomain:DFImageManagerErrorDomain code:DFImageManagerErrorCancelled userInfo:nil];
            task.response = [DFImageResponse responseWithError:error];
        }
        if (state == DFImageTaskStateCompleted) {
            if (!task.response.image && !task.response.error) {
                NSError *error = [NSError errorWithDomain:DFImageManagerErrorDomain code:DFImageManagerErrorUnknown userInfo:nil];
                task.response = [[DFImageResponse alloc] initWithImage:nil error:error userInfo:task.response.userInfo];
            }
        }
        DFImageTaskCompletion completion = task.completionHandler;
        if (completion) {
            NSDictionary *info = [self _infoFromResponse:task.response task:task];
            dispatch_async(dispatch_get_main_queue(), ^{
                task.error = task.response.error;
                completion(task.response.image, info);
                task.response = nil;
            });
        }
    }
}

- (void)getImageTasksWithCompletion:(void (^ __nullable)(NSArray * __nonnull, NSArray * __nonnull))completion {
    [self lock];
    NSMutableSet *tasks = [NSMutableSet new];
    NSMutableSet *preheatingTasks = [NSMutableSet new];
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
    dispatch_async(dispatch_get_main_queue(), ^{
        completion([tasks allObjects], [preheatingTasks allObjects]);
    });
    [self unlock];
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

#pragma mark <DFImageManaging> Preheating

- (void)startPreheatingImagesForRequests:(nonnull NSArray *)requests {
    [self lock];
    if (_invalidated) {
        return;
    }
    for (DFImageRequest *request in [self _canonicalRequestsForRequests:requests]) {
        id<NSCopying> key = [_imageLoder processingKeyForRequest:request];
        if (!_preheatingTasks[key]) {
            DFImageManager *__weak weakSelf = self;
            _DFImageTask *task = [[_DFImageTask alloc] initWithManager:self request:request completionHandler:^(UIImage *image, NSDictionary *info) {
                DFImageManager *strongSelf = weakSelf;
                if (strongSelf) {
                    @synchronized(self) {
                        [strongSelf->_preheatingTasks removeObjectForKey:key];
                    }
                }
            }];
            task.preheating = YES;
            task.tag = _preheatingTaskCounter++;
            _preheatingTasks[key] = task;
        }
    }
    [self _setNeedsExecutePreheatingTasks];
    [self unlock];
}

- (void)stopPreheatingImagesForRequests:(nonnull NSArray *)requests {
    [self lock];
    for (DFImageRequest *request in [self _canonicalRequestsForRequests:requests]) {
        id<NSCopying> key = [_imageLoder processingKeyForRequest:request];
        _DFImageTask *task = _preheatingTasks[key];
        if (task) {
            [self _setImageTaskState:DFImageTaskStateCancelled task:task];
            [_preheatingTasks removeObjectForKey:key];
        }
    }
    [self unlock];
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

#pragma mark <NSLocking>

- (void)lock {
    [_lock lock];
}

- (void)unlock {
    [_lock unlock];
}

#pragma mark Support

- (nonnull NSArray *)_canonicalRequestsForRequests:(nonnull NSArray *)requests {
    NSMutableArray *canonicalRequests = [[NSMutableArray alloc] initWithCapacity:requests.count];
    for (DFImageRequest *request in requests) {
        [canonicalRequests addObject:[_imageLoder canonicalRequestForRequest:request]];
    }
    return canonicalRequests;
}

- (nonnull NSMutableDictionary *)_infoFromResponse:(nonnull DFImageResponse *)response task:(nonnull _DFImageTask *)task {
    NSMutableDictionary *info = [NSMutableDictionary new];
    if (response.error) {
        info[DFImageInfoErrorKey] = response.error;
    }
    [info addEntriesFromDictionary:response.userInfo];
    info[DFImageInfoTaskKey] = task;
    return info;
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
    [self _resumeImageTask:task];
}

- (void)cancelTask:(nonnull _DFImageTask *)task {
    [self lock];
    [self _setImageTaskState:DFImageTaskStateCancelled task:task];
    [self unlock];
}

- (void)setPriority:(DFImageRequestPriority)priority forTask:(nonnull _DFImageTask *)task {
    [self lock];
    if (task.request.options.priority != priority) {
        task.request.options.priority = priority;
        [_imageLoder updatePriorityForTask:task.loadTask];
    }
    [self unlock];
}

@end
