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
#import "DFImageProcessing.h"
#import "DFImageRequest.h"
#import "DFImageTask.h"
#import "DFImageRequestOptions.h"
#import "DFImageResponse.h"

#if DF_IMAGE_MANAGER_GIF_AVAILABLE
#import "DFImageManagerKit+GIF.h"
#endif

#pragma mark - _DFImageTask

@class _DFImageTask;
@class _DFImageFetchOperation;

@interface DFImageManager (_DFImageTask)

- (void)resumeTask:(_DFImageTask *)task;
- (void)cancelTask:(_DFImageTask *)task;
- (void)setPriority:(DFImageRequestPriority)priority forTask:(_DFImageTask *)task;

@end

@interface _DFImageTask : DFImageTask

@property (nonatomic, readonly) DFImageManager *manager;
@property (nonatomic) DFImageTaskState state;
@property (nonatomic) NSError *error;
@property (nonatomic) DFImageResponse *response;
@property (nonatomic) NSInteger tag;
@property (nonatomic) BOOL preheating;
@property (nonatomic, weak) _DFImageFetchOperation *fetchOperation;
@property (nonatomic, weak) NSOperation *processOperation;

@end

@implementation _DFImageTask

@synthesize completionHandler = _completionHandler;
@synthesize request = _request;
@synthesize error = _error;
@synthesize state = _state;

- (instancetype)initWithManager:(DFImageManager *)manager request:(DFImageRequest *)request completionHandler:(DFImageRequestCompletion)completionHandler {
    if (self = [super init]) {
        _manager = manager;
        _request = request;
        _completionHandler = completionHandler;
        _state = DFImageTaskStateSuspended;
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


#pragma mark - _DFImageRequestKey

@class _DFImageRequestKey;

@protocol _DFImageRequestKeyOwner <NSObject>

- (BOOL)isImageRequestKey:(_DFImageRequestKey *)key1 equalToKey:(_DFImageRequestKey *)key2;

@end

/*! Make it possible to use DFImageRequest as a key in dictionaries (and dictionary-like structures). Requests may be interpreted differently so we compare them using <DFImageFetching> -isRequestFetchEquivalent:toRequest: method and (optionally) similar <DFImageProcessing> method.
 */
@interface _DFImageRequestKey : NSObject <NSCopying>

@property (nonatomic, readonly) DFImageRequest *request;
@property (nonatomic, readonly) BOOL isCacheKey;
@property (nonatomic, weak, readonly) id<_DFImageRequestKeyOwner> owner;

- (instancetype)initWithRequest:(DFImageRequest *)request isCacheKey:(BOOL)isCacheKey owner:(id<_DFImageRequestKeyOwner>)owner;

@end

@implementation _DFImageRequestKey {
    NSUInteger _hash;
}

- (instancetype)initWithRequest:(DFImageRequest *)request isCacheKey:(BOOL)isCacheKey owner:(id<_DFImageRequestKeyOwner>)owner {
    if (self = [super init]) {
        _request = request;
        _hash = [request.resource hash];
        _isCacheKey = isCacheKey;
        _owner = owner;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (NSUInteger)hash {
    return _hash;
}

- (BOOL)isEqual:(_DFImageRequestKey *)other {
    if (other == self) {
        return YES;
    }
    if (other.owner != self.owner) {
        return NO;
    }
    return [self.owner isImageRequestKey:self equalToKey:other];
}

@end


#pragma mark - _DFImageFetchOperation

@interface _DFImageFetchOperation : NSObject

@property (nonatomic, readonly) DFImageRequest *request;
@property (nonatomic, readonly) _DFImageRequestKey *key;
@property (nonatomic) NSOperation *operation;
@property (nonatomic) NSMutableSet *imageTasks;

@end

@implementation _DFImageFetchOperation

- (instancetype)initWithRequest:(DFImageRequest *)request key:(_DFImageRequestKey *)key {
    if (self = [super init]) {
        _request = request;
        _key = key;
        _imageTasks = [NSMutableSet new];
    }
    return self;
}

- (void)updateOperationPriority {
    if (_operation && _imageTasks.count) {
        DFImageRequestPriority priority = DFImageRequestPriorityVeryLow;
        for (_DFImageTask *task in _imageTasks) {
            priority = MAX(task.request.options.priority, priority);
        }
        if (_operation.queuePriority != (NSOperationQueuePriority)priority) {
            _operation.queuePriority = (NSOperationQueuePriority)priority;
        }
    }
}

@end


#pragma mark - DFImageManager

#define DFImageCacheKeyCreate(request) [[_DFImageRequestKey alloc] initWithRequest:request isCacheKey:YES owner:self]
#define DFImageLoadKeyCreate(request) [[_DFImageRequestKey alloc] initWithRequest:request isCacheKey:NO owner:self]

@interface DFImageManager () <_DFImageRequestKeyOwner>

@end

@implementation DFImageManager {
    dispatch_queue_t _queue;
    NSMutableSet /* _DFImageTask */ *_executingImageTasks;
    NSMutableDictionary /* _DFImageRequestKey : _DFImageFetchOperation */ *_fetchOperations;
    NSMutableDictionary /* _DFImageRequestKey : _DFImageTask */ *_preheatingTasks;
    NSInteger _preheatingTaskCounter;
    BOOL _invalidated;
    BOOL _needsToExecutePreheatTasks;
    BOOL _fetcherRespondsToCanonicalRequest;
}

@synthesize configuration = _conf;

- (nonnull instancetype)initWithConfiguration:(nonnull DFImageManagerConfiguration *)configuration {
    if (self = [super init]) {
        NSParameterAssert(configuration);
        _conf = [configuration copy];
        
        _queue = dispatch_queue_create([[NSString stringWithFormat:@"%@-queue-%p", [self class], self] UTF8String], DISPATCH_QUEUE_SERIAL);
        _preheatingTasks = [NSMutableDictionary new];
        _executingImageTasks = [NSMutableSet new];
        _fetchOperations = [NSMutableDictionary new];
        
        _fetcherRespondsToCanonicalRequest = [_conf.fetcher respondsToSelector:@selector(canonicalRequestForRequest:)];
    }
    return self;
}

#pragma mark <DFImageManaging>

- (BOOL)canHandleRequest:(nonnull DFImageRequest *)request {
    NSParameterAssert(request);
    return [_conf.fetcher canHandleRequest:request];
}

- (nullable DFImageTask *)imageTaskForResource:(nonnull id)resource completion:(nullable DFImageRequestCompletion)completion {
    NSParameterAssert(resource);
    return [self imageTaskForRequest:[DFImageRequest requestWithResource:resource] completion:completion];
}

- (nullable DFImageTask *)imageTaskForRequest:(nonnull DFImageRequest *)request completion:(nullable DFImageRequestCompletion)completion {
    NSParameterAssert(request);
    if (_invalidated) {
        return nil;
    }
    return [[_DFImageTask alloc] initWithManager:self request:[self _canonicalRequestForRequest:request] completionHandler:completion];
}

- (void)_resumeImageTask:(_DFImageTask *)task {
    if (_invalidated) {
        return;
    }
    if ([NSThread isMainThread]) {
        DFImageResponse *response = [self _cachedResponseForRequest:task.request];
        if (response.image) {
            task.state = DFImageTaskStateCompleted;
            if (task.completionHandler) {
                NSMutableDictionary *info = [self _infoFromResponse:response task:task];
                info[DFImageInfoIsFromMemoryCacheKey] = @YES;
                task.completionHandler(response.image, info);
            }
            return;
        }
    }
    dispatch_async(_queue, ^{
        [self _setImageTaskState:DFImageTaskStateRunning task:task];
    });
}

- (void)_setImageTaskState:(DFImageTaskState)state task:(_DFImageTask *)task {
    if ([task isValidNextState:state]) {
        [self _transitionActionFromState:task.state toState:state task:task];
        task.state = state;
        [self _enterActionForState:state task:task];
    }
}

- (void)_transitionActionFromState:(DFImageTaskState)fromState toState:(DFImageTaskState)toState task:(_DFImageTask *)task {
    if (fromState == DFImageTaskStateRunning && toState == DFImageTaskStateCancelled) {
        _DFImageFetchOperation *fetchOperation = task.fetchOperation;
        if (fetchOperation) {
            [fetchOperation.imageTasks removeObject:task];
            if (fetchOperation.imageTasks.count == 0) {
                [fetchOperation.operation cancel];
                [_fetchOperations removeObjectForKey:fetchOperation.key];
            }
        }
        [task.processOperation cancel];
    }
}

- (void)_enterActionForState:(DFImageTaskState)state task:(_DFImageTask *)task {
    if (state == DFImageTaskStateRunning) {
        [_executingImageTasks addObject:task];
        
        _DFImageRequestKey *operationKey = DFImageLoadKeyCreate(task.request);
        _DFImageFetchOperation *operation = _fetchOperations[operationKey];
        if (!operation) {
            operation = [[_DFImageFetchOperation alloc] initWithRequest:task.request key:operationKey];
            DFImageManager *__weak weakSelf = self;
            operation.operation = [_conf.fetcher startOperationWithRequest:task.request progressHandler:^(double progress) {
                [weakSelf _imageFetchOperation:operation didUpdateProgress:progress];
            } completion:^(DFImageResponse *response) {
                [weakSelf _imageFetchOperation:operation didCompleteWithResponse:response];
            }];
            _fetchOperations[operationKey] = operation;
        }
        [operation.imageTasks addObject:task];
        [operation updateOperationPriority];
        task.fetchOperation = operation;
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
        if (task.completionHandler) {
            NSDictionary *info = [self _infoFromResponse:task.response task:task];
            dispatch_async(dispatch_get_main_queue(), ^{
                task.error = task.response.error;
                task.completionHandler(task.response.image, info);
                task.response = nil;
            });
        }
    }
}

- (void)_imageFetchOperation:(_DFImageFetchOperation *)operation didUpdateProgress:(double)progress {
    dispatch_async(_queue, ^{
        for (_DFImageTask *task in operation.imageTasks) {
            void (^progressHandler)(double) = task.request.options.progressHandler;
            if (progressHandler) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    progressHandler(progress);
                });
            }
        }
    });
}

- (void)_imageFetchOperation:(_DFImageFetchOperation *)operation didCompleteWithResponse:(DFImageResponse *)response {
    dispatch_async(_queue, ^{
        for (_DFImageTask *task in operation.imageTasks) {
            task.fetchOperation = nil;
            if (response.image) {
                DFImageManager *__weak weakSelf = self;
                [self _processResponse:response task:task completion:^(DFImageResponse *processedResponse) {
                    task.response = processedResponse;
                    dispatch_async(_queue, ^{
                        [weakSelf _setImageTaskState:DFImageTaskStateCompleted task:task];
                    });
                }];
            } else {
                task.response = response;
                [self _setImageTaskState:DFImageTaskStateCompleted task:task];
            }
        }
        operation.imageTasks = nil;
        [_fetchOperations removeObjectForKey:operation.key];
    });
}

- (void)_processResponse:(DFImageResponse *)response task:(_DFImageTask *)task completion:(void (^)(DFImageResponse *processedResponse))completion {
    DFImageRequest *request = task.request;
    BOOL shouldProcessResponse = _conf.processor != nil;
#if DF_IMAGE_MANAGER_GIF_AVAILABLE
    if ([response.image isKindOfClass:[DFAnimatedImage class]]) {
        shouldProcessResponse = NO;
    }
#endif
    if (shouldProcessResponse) {
        DFImageManager *__weak weakSelf = self;
        id<DFImageProcessing> processor = _conf.processor;
        NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            DFImageResponse *processedResponse = [weakSelf _cachedResponseForRequest:request];
            if (!processedResponse) {
                UIImage *processedImage = [processor processedImage:response.image forRequest:request];
                processedResponse = [[DFImageResponse alloc] initWithImage:processedImage error:response.error userInfo:response.userInfo];
                [weakSelf _storeResponse:processedResponse forRequest:request];
            }
            completion(processedResponse);
        }];
        task.processOperation = operation;
        [_conf.processingQueue addOperation:operation];
    } else {
        [self _storeResponse:response forRequest:request];
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(response);
        });
    }
}

- (void)getImageTasksWithCompletion:(void (^)(NSArray *, NSArray *))completion {
    dispatch_async(_queue, ^{
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
    });
}

- (void)invalidateAndCancel {
    if (!_invalidated) {
        _invalidated = YES;
        dispatch_async(_queue, ^{
            [_preheatingTasks removeAllObjects];
            for (_DFImageTask *task in _executingImageTasks) {
                [self _setImageTaskState:DFImageTaskStateCancelled task:task];
            }
        });
    }
}

#pragma mark Preheating

- (void)startPreheatingImagesForRequests:(NSArray *)requests {
    if (_invalidated) {
        return;
    }
    dispatch_async(_queue, ^{
        for (DFImageRequest *request in [self _canonicalRequestsForRequests:requests]) {
            _DFImageRequestKey *key = DFImageCacheKeyCreate(request);
            if (!_preheatingTasks[key]) {
                DFImageManager *__weak weakSelf = self;
                _DFImageTask *task = [[_DFImageTask alloc] initWithManager:self request:request completionHandler:^(UIImage *image, NSDictionary *info) {
                    DFImageManager *strongSelf = weakSelf;
                    if (strongSelf) {
                        dispatch_async(strongSelf->_queue, ^{
                            [strongSelf->_preheatingTasks removeObjectForKey:key];
                        });
                    }
                }];
                task.preheating = YES;
                task.tag = _preheatingTaskCounter++;
                _preheatingTasks[key] = task;
            }
        }
        [self _setNeedsExecutePreheatingTasks];
    });
}

- (void)stopPreheatingImagesForRequests:(NSArray *)requests {
    dispatch_async(_queue, ^{
        for (DFImageRequest *request in [self _canonicalRequestsForRequests:requests]) {
            _DFImageRequestKey *key = DFImageCacheKeyCreate(request);
            _DFImageTask *task = _preheatingTasks[key];
            if (task) {
                [self _setImageTaskState:DFImageTaskStateCancelled task:task];
                [_preheatingTasks removeObjectForKey:key];
            }
        }
    });
}

- (void)stopPreheatingImagesForAllRequests {
    dispatch_async(_queue, ^{
        for (_DFImageTask *task in _preheatingTasks.allValues) {
            [self _setImageTaskState:DFImageTaskStateCancelled task:task];
        }
        [_preheatingTasks removeAllObjects];
    });
}

- (void)_setNeedsExecutePreheatingTasks {
    if (!_needsToExecutePreheatTasks && !_invalidated) {
        _needsToExecutePreheatTasks = YES;
        // Manager won't start executing preheating tasks in case you are about to add normal (non-preheating) right after adding preheating ones.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), _queue, ^{
            [self _executePreheatingTasksIfNeeded];
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

#pragma mark <_DFImageRequestKeyOwner>

- (BOOL)isImageRequestKey:(_DFImageRequestKey *)lhs equalToKey:(_DFImageRequestKey *)rhs {
    if (lhs.isCacheKey) {
        if (![_conf.fetcher isRequestCacheEquivalent:lhs.request toRequest:rhs.request]) {
            return NO;
        }
        return _conf.processor ? [_conf.processor isProcessingForRequestEquivalent:lhs.request toRequest:rhs.request] : YES;
    } else {
        return [_conf.fetcher isRequestFetchEquivalent:lhs.request toRequest:rhs.request];
    }
}

#pragma mark Support

- (DFImageResponse *)_cachedResponseForRequest:(DFImageRequest *)request {
    return request.options.memoryCachePolicy != DFImageRequestCachePolicyReloadIgnoringCache ? [_conf.cache cachedImageResponseForKey:DFImageCacheKeyCreate(request)].response : nil;
}

- (void)_storeResponse:(DFImageResponse *)response forRequest:(DFImageRequest *)request {
    DFCachedImageResponse *cachedResponse = [[DFCachedImageResponse alloc] initWithResponse:response expirationDate:(CACurrentMediaTime() + request.options.expirationAge)];
    [_conf.cache storeImageResponse:cachedResponse forKey:DFImageCacheKeyCreate(request)];
}

- (NSArray *)_canonicalRequestsForRequests:(NSArray *)requests {
    NSMutableArray *canonicalRequests = [[NSMutableArray alloc] initWithCapacity:requests.count];
    for (DFImageRequest *request in requests) {
        [canonicalRequests addObject:[self _canonicalRequestForRequest:request]];
    }
    return canonicalRequests;
}

- (nonnull DFImageRequest *)_canonicalRequestForRequest:(nonnull DFImageRequest *)request {
    if (_fetcherRespondsToCanonicalRequest) {
        return [[_conf.fetcher canonicalRequestForRequest:[request copy]] copy];
    }
    return [request copy];
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

- (nullable DFImageTask *)requestImageForResource:(id __nonnull)resource completion:(nullable DFImageRequestCompletion)completion {
    return [self requestImageForRequest:[DFImageRequest requestWithResource:resource] completion:completion];
}

- (nullable DFImageTask *)requestImageForRequest:(DFImageRequest * __nonnull)request completion:(nullable DFImageRequestCompletion)completion {
    DFImageTask *task = [self imageTaskForRequest:request completion:completion];
    [task resume];
    return task;
}

#pragma clang diagnostic pop

@end


@implementation DFImageManager (_DFImageTask)

- (void)resumeTask:(_DFImageTask *)task {
    [self _resumeImageTask:task];
}

- (void)cancelTask:(_DFImageTask *)task {
    dispatch_async(_queue, ^{
        [self _setImageTaskState:DFImageTaskStateCancelled task:task];
    });
}

- (void)setPriority:(DFImageRequestPriority)priority forTask:(_DFImageTask *)task {
    dispatch_async(_queue, ^{
        DFImageRequestOptions *options = task.request.options;
        if (options.priority != priority) {
            options.priority = priority;
            [task.fetchOperation updateOperationPriority];
        }
    });
}

@end
