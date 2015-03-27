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

#import "DFCachedImage.h"
#import "DFImageCaching.h"
#import "DFImageFetching.h"
#import "DFImageManager.h"
#import "DFImageManagerConfiguration.h"
#import "DFImageManagerDefines.h"
#import "DFImageProcessing.h"
#import "DFImageRequest.h"
#import "DFImageRequestID.h"
#import "DFImageRequestOptions.h"
#import "DFImageResponse.h"

#if __has_include("DFImageManagerKit+GIF.h") && !(DF_IMAGE_MANAGER_FRAMEWORK_TARGET)
#import "DFImageManagerKit+GIF.h"
#endif

#pragma mark - _DFImageTask

@class _DFImageTask;
@class _DFImageFetchOperation;

typedef NS_ENUM(NSUInteger, _DFImageTaskState) {
    _DFImageTaskStateSuspended,
    _DFImageTaskStateRunning,
    _DFImageTaskStateCancelled,
    _DFImageTaskStateCompleted
};

@interface DFImageManager (_DFImageTask)

- (void)cancelTask:(_DFImageTask *)task;
- (void)setPriority:(DFImageRequestPriority)priority forTask:(_DFImageTask *)task;

@end

@interface _DFImageTask : DFImageRequestID

@property (nonatomic, readonly, weak) DFImageManager *imageManager;
@property (nonatomic, readonly) DFImageRequest *request;
@property (nonatomic, readonly, copy) DFImageRequestCompletion completionHandler;
@property (nonatomic) DFImageResponse *response;
@property (nonatomic) _DFImageTaskState state;
@property (nonatomic) NSInteger tag;

@property (nonatomic, weak) _DFImageFetchOperation *fetchOperation;
@property (nonatomic, weak) NSOperation *processOperation;

@end

@implementation _DFImageTask

- (instancetype)initWithManager:(DFImageManager *)imageManager request:(DFImageRequest *)request completionHandler:(DFImageRequestCompletion)completionHandler {
    if (self = [super init]) {
        _imageManager = imageManager;
        _request = request;
        _completionHandler = [completionHandler copy];
        _state = _DFImageTaskStateSuspended;
    }
    return self;
}

- (void)cancel {
    [self.imageManager cancelTask:self];
}

- (void)setPriority:(DFImageRequestPriority)priority {
    [self.imageManager setPriority:priority forTask:self];
}

@end


#pragma mark - _DFImageRequestKey

@class _DFImageRequestKey;

/*! The delegate that implements key comparing.
 */
@protocol _DFImageRequestKeyDelegate <NSObject>

- (BOOL)isImageRequestKeyEqual:(_DFImageRequestKey *)key1 toKey:(_DFImageRequestKey *)key2;

@end

/*! Make it possible to use DFImageRequest as a key in dictionaries (and dictionary-like structures). Requests may be interpreted differently so we compare them using <DFImageFetching> -isRequestFetchEquivalent:toRequest: method and (optionally) similar <DFImageProcessing> method.
 */
@interface _DFImageRequestKey : NSObject <NSCopying>

@property (nonatomic, readonly) DFImageRequest *request;
@property (nonatomic, readonly) BOOL isCacheKey;
@property (nonatomic, weak, readonly) id<_DFImageRequestKeyDelegate> delegate;

- (instancetype)initWithRequest:(DFImageRequest *)request isCacheKey:(BOOL)isCacheKey delegate:(id<_DFImageRequestKeyDelegate>)delegate;

@end

@implementation _DFImageRequestKey {
    NSUInteger _hash;
}

- (instancetype)initWithRequest:(DFImageRequest *)request isCacheKey:(BOOL)isCacheKey delegate:(id<_DFImageRequestKeyDelegate>)delegate {
    if (self = [super init]) {
        _request = request;
        _hash = [request.resource hash];
        _isCacheKey = isCacheKey;
        _delegate = delegate;
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
    if (other.delegate != self.delegate) {
        return NO;
    }
    return [self.delegate isImageRequestKeyEqual:self toKey:other];
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

#define DFImageCacheKeyCreate(request) [[_DFImageRequestKey alloc] initWithRequest:request isCacheKey:YES delegate:self]
#define DFImageLoadKeyCreate(request) [[_DFImageRequestKey alloc] initWithRequest:request isCacheKey:NO delegate:self]

@interface DFImageManager () <_DFImageRequestKeyDelegate>

@property (nonatomic, readonly) NSMutableSet *executingImageTasks;
@property (nonatomic, readonly) NSMutableDictionary /* _DFImageRequestKey : _DFImageTask */ *preheatingTasks;
@property (nonatomic, readonly) NSMutableDictionary /* _DFImageRequestKey : _DFImageFetchOperation */ *fetchOperations;

@end

@implementation DFImageManager {
    dispatch_queue_t _queue;
    NSInteger _preheatingTaskCounter;
    BOOL _needsToExecutePreheatTasks;
    BOOL _fetcherRespondsToCanonicalRequest;
}

@synthesize configuration = _conf;

- (instancetype)initWithConfiguration:(DFImageManagerConfiguration *)configuration {
    if (self = [super init]) {
        if (!configuration) {
            [NSException raise:NSInternalInconsistencyException format:@"Initialized without configuration"];
        }
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

- (BOOL)canHandleRequest:(DFImageRequest *)request {
    return [_conf.fetcher canHandleRequest:request];
}

- (DFImageRequestID *)requestImageForResource:(id)resource completion:(void (^)(UIImage *, NSDictionary *))completion {
    return [self requestImageForRequest:[DFImageRequest requestWithResource:resource] completion:completion];
}

- (DFImageRequestID *)requestImageForRequest:(DFImageRequest *)request completion:(DFImageRequestCompletion)completion {
    if (!request.resource) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(nil, nil);
            }
        });
        return nil;
    }
    DFImageRequest *canonicalRequest = [self _canonicalRequestForRequest:request];
    if ([NSThread isMainThread]) {
        UIImage *image = [self _cachedImageForRequest:canonicalRequest];
        if (image) {
            if (completion) {
                completion(image, nil);
            }
            return nil;
        }
    }
    _DFImageTask *task = [[_DFImageTask alloc] initWithManager:self request:canonicalRequest completionHandler:completion];
    dispatch_async(_queue, ^{
        [self _setImageTaskState:_DFImageTaskStateRunning task:task];
    });
    return task;
}

- (void)_setImageTaskState:(_DFImageTaskState)state task:(_DFImageTask *)task {
    if ([DFImageManager _isTransitionAllowedFromState:task.state toState:state]) {
        [self _transitionActionFromState:task.state toState:state task:task];
        task.state = state;
        [self _enterActionForState:state task:task];
    }
}

+ (BOOL)_isTransitionAllowedFromState:(_DFImageTaskState)fromState toState:(_DFImageTaskState)toState {
    static NSDictionary *transitions;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        transitions = @{ @(_DFImageTaskStateSuspended) : @[ @(_DFImageTaskStateRunning),
                                                            @(_DFImageTaskStateCancelled) ],
                         @(_DFImageTaskStateRunning) : @[ @(_DFImageTaskStateCompleted),
                                                          @(_DFImageTaskStateCancelled) ] };
    });
    return [((NSArray *)transitions[@(fromState)]) containsObject:@(toState)];
}

- (void)_transitionActionFromState:(_DFImageTaskState)fromState toState:(_DFImageTaskState)toState task:(_DFImageTask *)task {
    if (fromState == _DFImageTaskStateRunning && toState == _DFImageTaskStateCancelled) {
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

- (void)_enterActionForState:(_DFImageTaskState)state task:(_DFImageTask *)task {
    if (state == _DFImageTaskStateRunning) {
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
    if (state == _DFImageTaskStateCompleted || state == _DFImageTaskStateCancelled) {
        [_executingImageTasks removeObject:task];
        [self _setNeedsExecutePreheatingTasks];
        
        if (state == _DFImageTaskStateCancelled) {
            NSError *error = [NSError errorWithDomain:DFImageManagerErrorDomain code:DFImageManagerErrorCancelled userInfo:nil];
            task.response = [DFImageResponse responseWithError:error];
        }
        
        if (task.completionHandler) {
            DFImageResponse *response = task.response;
            NSMutableDictionary *responseInfo = ({
                NSMutableDictionary *info = [NSMutableDictionary new];
                if (response.error) {
                    info[DFImageInfoErrorKey] = response.error;
                }
                [info addEntriesFromDictionary:response.userInfo];
                info[DFImageInfoRequestIDKey] = task;
                info;
            });
            dispatch_async(dispatch_get_main_queue(), ^{
                task.completionHandler(response.image, responseInfo);
            });
        }
    }
}

- (void)_imageFetchOperation:(_DFImageFetchOperation *)operation didUpdateProgress:(double)progress {
    dispatch_async(_queue, ^{
        for (_DFImageTask *task in operation.imageTasks) {
            if (task.request.options.progressHandler) {
                void (^progressHandler)(double) = task.request.options.progressHandler;
                if (progressHandler) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        progressHandler(progress);
                    });
                }
                
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
                [self _processImage:response.image task:task completion:^(UIImage *processedImage) {
                    task.response = [[DFImageResponse alloc] initWithImage:processedImage error:nil userInfo:response.userInfo];
                    dispatch_async(_queue, ^{
                        [weakSelf _setImageTaskState:_DFImageTaskStateCompleted task:task];
                    });
                }];
            } else {
                task.response = response;
                [self _setImageTaskState:_DFImageTaskStateCompleted task:task];
            }
        }
        operation.imageTasks = nil;
        [_fetchOperations removeObjectForKey:operation.key];
    });
}

- (void)_processImage:(UIImage *)image task:(_DFImageTask *)task completion:(void (^)(UIImage *processedImage))completion {
    DFImageRequest *request = task.request;
    BOOL shouldProcessResponse = _conf.processor != nil;
#if __has_include("DFImageManagerKit+GIF.h") && !(DF_IMAGE_MANAGER_FRAMEWORK_TARGET)
    if ([image isKindOfClass:[DFAnimatedImage class]]) {
        shouldProcessResponse = NO;
    }
#endif
    if (shouldProcessResponse) {
        DFImageManager *__weak weakSelf = self;
        id<DFImageProcessing> processor = _conf.processor;
        NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            UIImage *processedImage = [weakSelf _cachedImageForRequest:request];
            if (processedImage) {
                completion(processedImage);
            } else {
                processedImage = [processor processedImage:image forRequest:request];
                [weakSelf _storeImage:processedImage forRequest:request];
                completion(processedImage);
            }
        }];
        task.processOperation = operation;
        [_conf.processingQueue addOperation:operation];
    } else {
        [self _storeImage:image forRequest:request];
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(image);
        });
    }
}

#pragma mark Preheating

- (void)startPreheatingImagesForRequests:(NSArray *)requests {
    dispatch_async(_queue, ^{
        for (DFImageRequest *request in [self _canonicalRequestsForRequests:requests]) {
            _DFImageRequestKey *key = DFImageCacheKeyCreate(request);
            if (!_preheatingTasks[key]) {
                DFImageManager *__weak weakSelf = self;
                _DFImageTask *handler = [[_DFImageTask alloc] initWithManager:self request:request completionHandler:^(UIImage *image, NSDictionary *info) {
                    [weakSelf.preheatingTasks removeObjectForKey:key];
                }];
                handler.tag = _preheatingTaskCounter++;
                _preheatingTasks[key] = handler;
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
                [self _setImageTaskState:_DFImageTaskStateCancelled task:task];
                [_preheatingTasks removeObjectForKey:key];
            }
        }
    });
}

- (void)stopPreheatingImagesForAllRequests {
    dispatch_async(_queue, ^{
        for (_DFImageTask *task in _preheatingTasks.allValues) {
            [self _setImageTaskState:_DFImageTaskStateCancelled task:task];
        }
        [_preheatingTasks removeAllObjects];
    });
}

- (void)_setNeedsExecutePreheatingTasks {
    if (!_needsToExecutePreheatTasks) {
        _needsToExecutePreheatTasks = YES;
        // Manager won't start executing preheating tasks in case you are about to add normal (non-preheating) right after adding preheating ones.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), _queue, ^{
            [self _executePreheatingTasksIfNecesary];
            _needsToExecutePreheatTasks = NO;
        });
    }
}

- (void)_executePreheatingTasksIfNecesary {
    NSUInteger executingTaskCount = _executingImageTasks.count;
    if (executingTaskCount < _conf.maximumConcurrentPreheatingRequests) {
        for (_DFImageTask *task in [_preheatingTasks.allValues sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"tag" ascending:YES]]]) {
            if (executingTaskCount >= _conf.maximumConcurrentPreheatingRequests) {
                return;
            }
            if (task.state == _DFImageTaskStateSuspended) {
                [self _setImageTaskState:_DFImageTaskStateRunning task:task];
                executingTaskCount++;
            }
        }
    }
}

#pragma mark <_DFImageRequestKeyDelegate>

- (BOOL)isImageRequestKeyEqual:(_DFImageRequestKey *)key1 toKey:(_DFImageRequestKey *)key2 {
    DFImageRequest *request1 = key1.request;
    DFImageRequest *request2 = key2.request;
    if (key1.isCacheKey) {
        if (![_conf.fetcher isRequestCacheEquivalent:request1 toRequest:request2]) {
            return NO;
        }
        return _conf.processor ? [_conf.processor isProcessingForRequestEquivalent:request1 toRequest:request2] : YES;
    } else {
        return [_conf.fetcher isRequestFetchEquivalent:request1 toRequest:request2];
    }
}

#pragma mark - Support

- (UIImage *)_cachedImageForRequest:(DFImageRequest *)request {
    return request.options.memoryCachePolicy != DFImageRequestCachePolicyReloadIgnoringCache ? [_conf.cache cachedImageForKey:DFImageCacheKeyCreate(request)].image : nil;
}

- (void)_storeImage:(UIImage *)image forRequest:(DFImageRequest *)request {
    DFCachedImage *cachedImage = [[DFCachedImage alloc] initWithImage:image expirationDate:(CACurrentMediaTime() + request.options.expirationAge)];
    [_conf.cache storeImage:cachedImage forKey:DFImageCacheKeyCreate(request)];
}

- (NSArray *)_canonicalRequestsForRequests:(NSArray *)requests {
    NSMutableArray *canonicalRequests = [[NSMutableArray alloc] initWithCapacity:requests.count];
    for (DFImageRequest *request in requests) {
        DFImageRequest *canonicalRequest = [self _canonicalRequestForRequest:request];
        if (canonicalRequest.resource) {
            [canonicalRequests addObject:canonicalRequest];
        }
    }
    return canonicalRequests;
}

- (DFImageRequest *)_canonicalRequestForRequest:(DFImageRequest *)request {
    if (_fetcherRespondsToCanonicalRequest) {
        return [[_conf.fetcher canonicalRequestForRequest:[request copy]] copy];
    }
    return [request copy];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %p> { name = %@ }", [self class], self, self.name];
}

@end


@implementation DFImageManager (_DFImageTask)

- (void)cancelTask:(_DFImageTask *)task {
    dispatch_async(_queue, ^{
        [self _setImageTaskState:_DFImageTaskStateCancelled task:task];
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
