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

#if __has_include("DFImageManagerKit+GIF.h")
#import "DFImageManagerKit+GIF.h"
#endif

@class _DFImageHandler;
@class _DFImageManagerTask;

@interface DFImageManager (_DFImageHandler)

- (void)cancelRequestWithHandler:(_DFImageHandler *)handler;
- (void)setPriority:(DFImageRequestPriority)priority forRequestWithHandler:(_DFImageHandler *)handler;

@end

#pragma mark - _DFImageHandler -

@interface _DFImageHandler : DFImageRequestID

@property (nonatomic, weak, readonly) DFImageManager *imageManager;
@property (nonatomic, readonly) DFImageRequest *request;
@property (nonatomic, copy, readonly) DFImageRequestCompletion completionHandler;
@property (nonatomic, weak) _DFImageManagerTask *task;

- (instancetype)initWithImageManager:(DFImageManager *)imageManager request:(DFImageRequest *)request completionHandler:(DFImageRequestCompletion)completionHandler;

@end

@implementation _DFImageHandler

- (instancetype)initWithImageManager:(DFImageManager *)imageManager request:(DFImageRequest *)request completionHandler:(DFImageRequestCompletion)completionHandler {
    if (self = [super init]) {
        _imageManager = imageManager;
        _request = request;
        _completionHandler = [completionHandler copy];
    }
    return self;
}

- (void)cancel {
    [self.imageManager cancelRequestWithHandler:self];
}

- (void)setPriority:(DFImageRequestPriority)priority {
    [self.imageManager setPriority:priority forRequestWithHandler:self];
}

@end


#pragma mark - _DFPreheatingImageHandler -

@interface _DFPreheatingImageHandler : _DFImageHandler

@end

@implementation _DFPreheatingImageHandler

@end


#pragma mark - _DFImageRequestKey -

@class _DFImageRequestKey;

/*! The delegate that implements key comparing.
 */
@protocol _DFImageRequestKeyDelegate <NSObject>

- (BOOL)isImageRequestKeyEqual:(_DFImageRequestKey *)key1 toKey:(_DFImageRequestKey *)key2;

@end

/*! Make it possible to use DFImageRequest as a key in dictionaries (and dictionary-like structures). Requests may be interpreted differently so we compare them using <DFImageFetching> -isRequestFetchEquivalent:toRequest: method and (optionally) similar <DFImageProcessing> method.
 @note CFDictionary and CFDictionaryKeyCallBacks could be used instead, but the solution that uses _DFImageRequestKey is cleaner and it supports any structure that relies on -hash and -isEqual methods (NSSet, NSCache and others).
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


#pragma mark - _DFImageManagerTask -

@class _DFImageManagerTask;

@protocol _DFImageManagerTaskDelegate <NSObject>

/*! Gets called when task fetches image. Task may skip calling this method if it already has processed response for all handlers. The delegate should call the completion handler with a shouldContinue.
 @note This method is required for maintaining thread safety. The method is similar to NSURLSessionTask callbacks.
 */
- (void)task:(_DFImageManagerTask *)task didReceiveResponse:(DFImageResponse *)response completion:(void (^)(BOOL shouldContinue))completion;

/*! Gets called when task updates progress.
 */
- (void)task:(_DFImageManagerTask *)task didUpdateProgress:(double)progress;

/*! Gets called when task retrieves processed response.
 */
- (void)task:(_DFImageManagerTask *)task didProcessResponse:(DFImageResponse *)response forHandler:(_DFImageHandler *)handler;

- (UIImage *)task:(_DFImageManagerTask *)task cachedImageForRequest:(DFImageRequest *)request;

- (void)task:(_DFImageManagerTask *)task storeImage:(UIImage *)image forRequest:(DFImageRequest *)request;

@end


/*! Implements the entire flow of retrieving, processing and caching images. Requires synchronization from the user of the class.
 @note Not thread safe.
 */
@interface _DFImageManagerTask : NSObject

@property (nonatomic, readonly) DFImageRequest *request;
@property (nonatomic, readonly) NSSet *handlers;

@property (nonatomic, readonly) BOOL isExecuting;

/*! Returns YES if all the handlers registered with task are preheating handlers.
 */
@property (nonatomic, readonly) BOOL isPreheating;

@property (nonatomic, weak) id<_DFImageManagerTaskDelegate> delegate;

- (instancetype)initWithRequest:(DFImageRequest *)request fetcher:(id<DFImageFetching>)fecher processor:(id<DFImageProcessing>)processor processingQueue:(NSOperationQueue *)processingQueue NS_DESIGNATED_INITIALIZER;

- (void)resume;
- (void)cancel;
- (void)updateOperationPriority;

- (void)addHandler:(_DFImageHandler *)handler;
- (void)removeHandler:(_DFImageHandler *)handler;

@end

@implementation _DFImageManagerTask {
    NSMutableSet *_handlers;
    BOOL _isReportingProgress;
    BOOL _isFetching;
    
    id<DFImageFetching> _fetcher;
    id<DFImageProcessing> _processor;
    NSOperationQueue *_processingQueue;
    
    // Fetch
    NSOperation *_fetchOperation;
    DFImageResponse *_fetchResponse;
    
    // Processing
    NSMutableDictionary /* _DFImageHandler *handler : NSOperation */ *_processingOperations;
}

- (instancetype)initWithRequest:(DFImageRequest *)request fetcher:(id<DFImageFetching>)fecher processor:(id<DFImageProcessing>)processor processingQueue:(NSOperationQueue *)processingQueue {
    if (self = [super init]) {
        _request = request;
        _fetcher = fecher;
        _processor = processor;
        _handlers = [NSMutableSet new];
        _processingQueue = processingQueue;
        _processingOperations = [NSMutableDictionary new];
    }
    return self;
}

- (void)resume {
    NSAssert(!_isExecuting, nil);
    _isExecuting = YES;
    for (_DFImageHandler *handler in self.handlers) {
        [self _executeHandler:handler];
    }
}

- (void)_executeHandler:(_DFImageHandler *)handler {
    UIImage *cachedImage = [self _cachedImageForRequest:handler.request];
    if (cachedImage) {
        // Fulfill request with image from memory cache
        [self _didProcessResponse:[DFImageResponse responseWithImage:cachedImage] forHandler:handler];
    } else if (_fetchResponse) {
        // Start image processing if task already has original image
        [self _processResponseForHandler:handler];
    } else if (!_isFetching) {
        _isFetching = YES;
        [self _fetchImage];
    } else {
        // Do nothing, wait for response
    }
}

- (void)addHandler:(_DFImageHandler *)handler {
    [_handlers addObject:handler];
    [self _didUpdateHandlers];
    if (self.isExecuting) {
        [self _executeHandler:handler];
    }
}

- (void)removeHandler:(_DFImageHandler *)handler {
    [_handlers removeObject:handler];
    [self _didUpdateHandlers];
    [((NSOperation *)_processingOperations[handler]) cancel];
}

- (void)_didUpdateHandlers {
    _isReportingProgress = NO;
    _isPreheating = YES;
    for (_DFImageHandler *handler in _handlers) {
        if (handler.request.options.progressHandler) {
            _isReportingProgress = YES;
        }
        if (![handler isKindOfClass:[_DFPreheatingImageHandler class]]) {
            _isPreheating = NO;
        }
    }
    [self updateOperationPriority];
}

- (void)cancel {
    [_fetchOperation cancel];
    self.delegate = nil;
}

#pragma mark - Fetching

- (void)_fetchImage {
    _DFImageManagerTask *__weak weakSelf = self;
    _fetchOperation = [_fetcher startOperationWithRequest:self.request progressHandler:^(double progress) {
        [weakSelf _didUpdateFetchProgress:progress];
    } completion:^(DFImageResponse *response) {
        [weakSelf _didFetchImageWithResponse:response];
    }];
    [self updateOperationPriority];
}

- (void)_didUpdateFetchProgress:(double)progress {
    /*! Performance optimization for users that are not interested in progress reporting. Reduces DFImageManager internal queue usage.
     */
    if (_isReportingProgress) {
        [self.delegate task:self didUpdateProgress:progress];
    }
}

- (void)_didFetchImageWithResponse:(DFImageResponse *)response {
    _fetchOperation = nil;
    [self.delegate task:self didReceiveResponse:_fetchResponse completion:^(BOOL shouldContinue) {
        if (shouldContinue) {
            _fetchResponse = response;
            NSAssert(self.handlers.count > 0, @"Internal inconsistency");
            for (_DFImageHandler *handler in self.handlers) {
                [self _processResponseForHandler:handler];
            }
        }
    }];
}

#pragma mark - Processing

- (void)_processResponseForHandler:(_DFImageHandler *)handler {
    UIImage *fetchedImage = _fetchResponse.image;
    BOOL shouldProcessResponse = _processor != nil && _processingQueue != nil;
#if __has_include("DFImageManagerKit+GIF.h")
    if ([fetchedImage isKindOfClass:[DFAnimatedImage class]]) {
        shouldProcessResponse = NO;
    }
#endif
    if (shouldProcessResponse && fetchedImage) {
        _DFImageManagerTask *__weak weakSelf = self;
        [self _processImage:fetchedImage forHandler:handler completion:^(UIImage *image) {
            DFImageResponse *response = [[DFImageResponse alloc] initWithImage:image error:_fetchResponse.error userInfo:_fetchResponse.userInfo];
            [weakSelf _didProcessResponse:response forHandler:handler];
        }];
    } else {
        if (fetchedImage) {
            [self _storeImage:fetchedImage forRequest:handler.request];
        }
        [self _didProcessResponse:_fetchResponse forHandler:handler];
    }
}

- (void)_processImage:(UIImage *)input forHandler:(_DFImageHandler *)handler completion:(void (^)(UIImage *image))completion {
    UIImage *cachedImage = [self _cachedImageForRequest:handler.request];
    if (cachedImage) {
        completion(cachedImage);
    } else {
        _DFImageManagerTask *__weak weakSelf = self;
        NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            UIImage *processedImage = [weakSelf _cachedImageForRequest:handler.request];
            if (!processedImage) {
                processedImage = [_processor processedImage:input forRequest:handler.request];
                [weakSelf _storeImage:processedImage forRequest:handler.request];
            }
            completion(processedImage);
        }];
        if ([handler isKindOfClass:[_DFPreheatingImageHandler class]]) {
            operation.queuePriority = NSOperationQueuePriorityVeryLow;
        }
        [_processingQueue addOperation:operation];
        _processingOperations[handler] = operation;
    }
}

- (void)_didProcessResponse:(DFImageResponse *)response forHandler:(_DFImageHandler *)handler {
    [self.delegate task:self didProcessResponse:response forHandler:handler];
}

#pragma mark -

- (void)updateOperationPriority {
    if (_fetchOperation && _handlers.count) {
        DFImageRequestPriority __block priority = DFImageRequestPriorityVeryLow;
        for (_DFImageHandler *handler in _handlers) {
            priority = MAX(handler.request.options.priority, priority);
        }
        if (_fetchOperation.queuePriority != (NSOperationQueuePriority)priority) {
            _fetchOperation.queuePriority = (NSOperationQueuePriority)priority;
        }
    }
}

- (UIImage *)_cachedImageForRequest:(DFImageRequest *)request {
    return [self.delegate task:self cachedImageForRequest:request];
}

- (void)_storeImage:(UIImage *)image forRequest:(DFImageRequest *)request {
    [self.delegate task:self storeImage:image forRequest:request];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %p> { executing:%i, fetching:%i, preheating:%i }", [self class], self, self.isExecuting, _isFetching, self.isPreheating];
}

@end


#pragma mark - DFImageManager -

#define DFImageCacheKeyCreate(request) [[_DFImageRequestKey alloc] initWithRequest:request isCacheKey:YES delegate:self]
#define DFImageRequestKeyCreate(request) [[_DFImageRequestKey alloc] initWithRequest:request isCacheKey:NO delegate:self]

@interface DFImageManager () <_DFImageManagerTaskDelegate, _DFImageRequestKeyDelegate>

@end

/*! Implementation details.
 - Each request+completion pair has it's own assigned DFImageRequestID
 - Multiple request+completion pairs might be handled by the same execution task (_DFImageManagerTask)
 */
@implementation DFImageManager {
    /*! Only contains not cancelled tasks. */
    NSMutableDictionary /* _DFImageRequestKey : _DFImageManagerTask */ *_tasks;
    dispatch_queue_t _syncQueue;
    
    struct {
        unsigned int needsToExecutePreheatRequests:1;
        unsigned int fetcherRespondsToCanonicalRequest:1;
    } _flags;
}

@synthesize configuration = _conf;

- (instancetype)initWithConfiguration:(DFImageManagerConfiguration *)configuration {
    if (self = [super init]) {
        NSParameterAssert(configuration);
        _conf = [configuration copy];
        
        _syncQueue = dispatch_queue_create([[NSString stringWithFormat:@"%@-queue-%p", [self class], self] UTF8String], DISPATCH_QUEUE_SERIAL);
        _tasks = [NSMutableDictionary new];
        
        _flags.fetcherRespondsToCanonicalRequest = (unsigned int)[_conf.fetcher respondsToSelector:@selector(canonicalRequestForRequest:)];
    }
    return self;
}

#pragma mark - <DFImageManaging>

- (BOOL)canHandleRequest:(DFImageRequest *)request {
    return [_conf.fetcher canHandleRequest:request];
}

#pragma mark Fetching

- (DFImageRequestID *)requestImageForResource:(id)resource completion:(void (^)(UIImage *, NSDictionary *))completion {
    return [self requestImageForRequest:[DFImageRequest requestWithResource:resource] completion:completion];
}

- (DFImageRequestID *)requestImageForRequest:(DFImageRequest *)request completion:(DFImageRequestCompletion)completion {
    DFImageRequest *canonicalRequest = [self _canonicalRequestForRequest:request];
    if (_conf.allowsSynchronousMemoryCacheLookup && [NSThread isMainThread]) {
        UIImage *image = [self _cachedImageForRequest:canonicalRequest];
        if (image) {
            if (completion) {
                completion(image, nil);
            }
            return nil;
        }
    }
    _DFImageHandler *handler = [[_DFImageHandler alloc] initWithImageManager:self request:canonicalRequest completionHandler:completion]; // Represents requestID future.
    dispatch_async(_syncQueue, ^{
        [self _requestImageForHandler:handler];
    });
    return handler;
}

- (DFImageRequest *)_canonicalRequestForRequest:(DFImageRequest *)request {
    if (_flags.fetcherRespondsToCanonicalRequest) {
        return [[_conf.fetcher canonicalRequestForRequest:[request copy]] copy];
    }
    return [request copy];
}

- (void)_requestImageForHandler:(_DFImageHandler *)handler {
    _DFImageRequestKey *taskKey = DFImageRequestKeyCreate(handler.request);
    _DFImageManagerTask *task = _tasks[taskKey];
    if (!task) {
        task = [[_DFImageManagerTask alloc] initWithRequest:handler.request fetcher:_conf.fetcher processor:_conf.processor processingQueue:_conf.processingQueue];
        task.delegate = self;
        _tasks[taskKey] = task;
    }
    handler.task = task;
    [task addHandler:handler];
    
    /* Execute non-preheating tasks immediately. Existing preheating tasks may become non-preheating when new handlers are added.
     */
    if (!task.isExecuting && !task.isPreheating) {
        [task resume];
    } else {
        [self _setNeedsExecutePreheatingTasks];
    }
}

- (void)_removeTask:(_DFImageManagerTask *)task {
    [_tasks removeObjectForKey:DFImageRequestKeyCreate(task.request)];
    [self _setNeedsExecutePreheatingTasks];
}

#pragma mark - <_DFImageManagerTaskDelegate>

- (void)task:(_DFImageManagerTask *)task didReceiveResponse:(DFImageResponse *)response completion:(void (^)(BOOL))completion {
    dispatch_async(_syncQueue, ^{
        completion(task.handlers.count > 0);
    });
}

- (void)task:(_DFImageManagerTask *)task didUpdateProgress:(double)progress {
    dispatch_async(_syncQueue, ^{
        for (_DFImageHandler *handler in task.handlers) {
            void (^progressHandler)(double) = handler.request.options.progressHandler;
            if (progressHandler) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    progressHandler(progress);
                });
            }
        }
    });
}

- (void)task:(_DFImageManagerTask *)task didProcessResponse:(DFImageResponse *)response forHandler:(_DFImageHandler *)handler {
    dispatch_async(_syncQueue, ^{
        if ([task.handlers containsObject:handler]) { // TODO: Handle this using state machine
            [task removeHandler:handler];
            if (task.handlers.count == 0) {
                [self _removeTask:task];
            }
            if (handler.completionHandler) {
                NSMutableDictionary *responseInfo = ({
                    NSMutableDictionary *info = [NSMutableDictionary new];
                    if (response.error) {
                        info[DFImageInfoErrorKey] = response.error;
                    }
                    [info addEntriesFromDictionary:response.userInfo];
                    info[DFImageInfoRequestIDKey] = handler;
                    info;
                });
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler.completionHandler(response.image, responseInfo);
                });
            }
        }
    });
}

- (UIImage *)task:(_DFImageManagerTask *)task cachedImageForRequest:(DFImageRequest *)request {
    return [self _cachedImageForRequest:request];
}

- (UIImage *)_cachedImageForRequest:(DFImageRequest *)request {
    if (request.options.memoryCachePolicy != DFImageRequestCachePolicyReloadIgnoringCache) {
        return [_conf.cache cachedImageForKey:DFImageCacheKeyCreate(request)].image;
    }
    return nil;
}

- (void)task:(_DFImageManagerTask *)task storeImage:(UIImage *)image forRequest:(DFImageRequest *)request {
    DFCachedImage *cachedImage = [[DFCachedImage alloc] initWithImage:image expirationDate:(CACurrentMediaTime() + request.options.expirationAge)];
    [_conf.cache storeImage:cachedImage forKey:DFImageCacheKeyCreate(request)];
}

#pragma mark - <_DFImageRequestKeyDelegate>

- (BOOL)isImageRequestKeyEqual:(_DFImageRequestKey *)key1 toKey:(_DFImageRequestKey *)key2 {
    DFImageRequest *request1 = key1.request;
    DFImageRequest *request2 = key2.request;
    if (key1.isCacheKey) {
        if (![_conf.fetcher isRequestCacheEquivalent:request1 toRequest:request2]) {
            return NO;
        }
        if (!_conf.processor) {
            return YES;
        }
        return [_conf.processor isProcessingForRequestEquivalent:request1 toRequest:request2];
    } else {
        return [_conf.fetcher isRequestFetchEquivalent:request1 toRequest:request2];
    }
}

#pragma mark Preheating

- (void)startPreheatingImagesForRequests:(NSArray *)requests {
    if (requests.count) {
        dispatch_async(_syncQueue, ^{
            [self _startPreheatingImageForRequests:[self _canonicalRequestsForRequests:requests]];
        });
    }
}

- (void)_startPreheatingImageForRequests:(NSArray *)requests {
    for (DFImageRequest *request in requests) {
        _DFImageManagerTask *task = _tasks[DFImageRequestKeyCreate(request)];
        if (!task || ![self _preheatingHandlerForRequest:request task:task]) {
            _DFPreheatingImageHandler *handler = [[_DFPreheatingImageHandler alloc] initWithImageManager:self request:request completionHandler:nil];
            [self _requestImageForHandler:handler];
        }
    }
}

- (void)stopPreheatingImagesForRequests:(NSArray *)requests {
    if (requests.count) {
        dispatch_async(_syncQueue, ^{
            [self _stopPreheatingImagesForRequests:[self _canonicalRequestsForRequests:requests]];
        });
    }
}

- (void)_stopPreheatingImagesForRequests:(NSArray *)requests {
    for (DFImageRequest *request in requests) {
        _DFImageManagerTask *task = _tasks[DFImageRequestKeyCreate(request)];
        _DFImageHandler *handler = [self _preheatingHandlerForRequest:request task:task];
        if (handler) {
            [self _cancelRequestWithHandler:handler];
        }
    }
}

- (NSArray *)_canonicalRequestsForRequests:(NSArray *)requests {
    NSMutableArray *canonicalRequests = [[NSMutableArray alloc] initWithCapacity:requests.count];
    for (DFImageRequest *request in requests) {
        DFImageRequest *canonicalRequest = [self _canonicalRequestForRequest:request];
        if (canonicalRequest) {
            [canonicalRequests addObject:canonicalRequest];
        }
    }
    return canonicalRequests;
}

- (_DFPreheatingImageHandler *)_preheatingHandlerForRequest:(DFImageRequest *)request task:(_DFImageManagerTask *)task {
    for (_DFImageHandler *handler in task.handlers) {
        if ([handler isKindOfClass:[_DFPreheatingImageHandler class]]) {
            if (!_conf.processor || [_conf.processor isProcessingForRequestEquivalent:handler.request toRequest:request]) {
                return (_DFPreheatingImageHandler *)handler;
            }
        }
    }
    return nil;
}

- (void)stopPreheatingImagesForAllRequests {
    dispatch_async(_syncQueue, ^{
        NSMutableArray *handlers = [NSMutableArray new];
        for (_DFImageManagerTask *task in _tasks.allValues) {
            for (_DFImageHandler *handler in task.handlers) {
                if ([handler isKindOfClass:[_DFPreheatingImageHandler class]]) {
                    [handlers addObject:handler];
                }
            }
        }
        for (_DFImageHandler *handler in handlers) {
            [self _cancelRequestWithHandler:handler];
        }
    });
}

- (void)_setNeedsExecutePreheatingTasks {
    if (!_flags.needsToExecutePreheatRequests) {
        _flags.needsToExecutePreheatRequests = YES;
        /* Delays serves double purpose:
         - Image manager won't start executing preheating requests in case you are about to add normal (non-preheating) right after adding preheating ones.
         - Image manager won't execute relatively -_executePreheatingTasksIfNecesary method too often.
         */
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), _syncQueue, ^{
            [self _executePreheatingTasksIfNecesary];
            _flags.needsToExecutePreheatRequests = NO;
        });
    }
}

/*! Image manager will not execute preheating tasks until there is a least one regular executing task left. The number of concurrent preheating tasks is limited.
 */
- (void)_executePreheatingTasksIfNecesary {
    NSArray *executingTasks = [_tasks.allValues filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isExecuting = YES"]];
    if (executingTasks.count < _conf.maximumConcurrentPreheatingRequests) {
        for (_DFImageManagerTask *task in executingTasks) {
            if (!task.isPreheating) { // Is executing regular tasks
                return;
            }
        }
        NSArray *pendingTasks = [_tasks.allValues filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isExecuting = NO"]];
        NSUInteger executingTaskCount = executingTasks.count;
        for (_DFImageManagerTask *task in pendingTasks) {
            if (executingTaskCount >= _conf.maximumConcurrentPreheatingRequests) {
                break;
            }
            executingTaskCount++;
            [task resume];
        }
    }
}

#pragma mark - DFImageManager (_DFImageHandler)

- (void)cancelRequestWithHandler:(_DFImageHandler *)handler {
    dispatch_async(_syncQueue, ^{
        [self _cancelRequestWithHandler:handler];
    });
}

- (void)_cancelRequestWithHandler:(_DFImageHandler *)handler {
    _DFImageManagerTask *task = handler.task;
    if ([task.handlers containsObject:handler]) {
        [task removeHandler:handler];
        if (handler.completionHandler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                handler.completionHandler(nil, @{ DFImageInfoErrorKey: [NSError errorWithDomain:DFImageManagerErrorDomain code:DFImageManagerErrorCancelled userInfo:nil] });
            });
        }
        if (task.handlers.count == 0) {
            [task cancel];
            [self _removeTask:task];
        }
    }
}

- (void)setPriority:(DFImageRequestPriority)priority forRequestWithHandler:(_DFImageHandler *)handler {
    dispatch_async(_syncQueue, ^{
        DFImageRequestOptions *options = handler.request.options;
        if (options.priority != priority) {
            options.priority = priority;
            [handler.task updateOperationPriority];
        }
    });
}

#pragma mark -

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %p> { name = %@ }", [self class], self, self.name];
}

@end
