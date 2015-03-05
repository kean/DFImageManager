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
#import "DFProcessingImageFetcher.h"
#import "DFProcessingInput.h"

#if __has_include("DFAnimatedImage.h")
#import "DFAnimatedImage.h"
#endif

#pragma mark - _DFImageRequestID -

/*! Private DFImageRequestID implementation used by DFImageManager.
 */
@interface _DFImageRequestID : DFImageRequestID

/*! Image manager that originated request ID.
 */
@property (nonatomic, weak, readonly) id<DFImageManagingCore> imageManager;

@property (nonatomic, readonly) NSUUID *taskID;
@property (nonatomic, readonly) NSUUID *handlerID;

- (instancetype)initWithImageManager:(id<DFImageManagingCore>)imageManager;

- (void)setTaskID:(NSUUID *)taskID handlerID:(NSUUID *)handlerID;

@end

@implementation _DFImageRequestID

- (instancetype)initWithImageManager:(id<DFImageManagingCore>)imageManager {
    if (self = [super init]) {
        _imageManager = imageManager;
    }
    return self;
}

- (void)setTaskID:(NSUUID *)taskID handlerID:(NSUUID *)handlerID {
    if (_taskID || _handlerID) {
        [NSException raise:NSInternalInconsistencyException format:@"Attempting to rewrite image request state"];
    }
    _taskID = taskID;
    _handlerID = handlerID;
}

- (void)cancel {
    [self.imageManager cancelRequestWithID:self];
}

- (void)setPriority:(DFImageRequestPriority)priority {
    [self.imageManager setPriority:priority forRequestWithID:self];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %p> { manager = %@, taskID = %@, handlerID = %@ }", [self class], self, self.imageManager, self.taskID, self.handlerID];
}

@end


#pragma mark - _DFImageManagerHandler -

@interface _DFImageManagerHandler : NSObject

@property (nonatomic, readonly) DFImageRequest *request;
@property (nonatomic, readonly) _DFImageRequestID *requestID;
@property (nonatomic, copy, readonly) DFImageRequestCompletion completion;

- (instancetype)initWithRequest:(DFImageRequest *)request requestID:(DFImageRequestID *)requestID completion:(DFImageRequestCompletion)completion NS_DESIGNATED_INITIALIZER;

@end

@implementation _DFImageManagerHandler

- (instancetype)initWithRequest:(DFImageRequest *)request requestID:(_DFImageRequestID *)requestID completion:(DFImageRequestCompletion)completion {
    if (self = [super init]) {
        _request = request;
        _requestID = requestID;
        _completion = [completion copy];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %p> { handlerID = %@ }", [self class], self, self.requestID.handlerID];
}

@end


#pragma mark - _DFImageManagerPreheatHandler -

@interface _DFImageManagerPreheatHandler : _DFImageManagerHandler

@end

@implementation _DFImageManagerPreheatHandler

@end


#pragma mark - _DFImageRequestKey -

@class _DFImageRequestKey;

/*! The implementation of key comparer. Keys are only compared when they have the same delegate instance.
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
@property (nonatomic, weak) id<_DFImageRequestKeyDelegate> delegate;

- (instancetype)initWithRequest:(DFImageRequest *)request isCacheKey:(BOOL)isCacheKey;

@end

@implementation _DFImageRequestKey {
    NSUInteger _hash;
}

- (instancetype)initWithRequest:(DFImageRequest *)request isCacheKey:(BOOL)isCacheKey {
    if (self = [super init]) {
        _request = request;
        _hash = [request.resource hash];
        _isCacheKey = isCacheKey;
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

static inline _DFImageRequestKey *
_DFImageKeyCreate(DFImageRequest *request, BOOL isCacheKey, id<_DFImageRequestKeyDelegate> delegate) {
    _DFImageRequestKey *key = [[_DFImageRequestKey alloc] initWithRequest:request isCacheKey:isCacheKey];
    key.delegate = delegate;
    return key;
}


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
- (void)task:(_DFImageManagerTask *)task didProcessResponse:(DFImageResponse *)response forHandler:(_DFImageManagerHandler *)handler;

- (UIImage *)task:(_DFImageManagerTask *)task cachedImageForRequest:(DFImageRequest *)request;

- (void)task:(_DFImageManagerTask *)task storeImage:(UIImage *)image forRequest:(DFImageRequest *)request;

@end


/*! Implements the entire flow of retrieving, processing and caching images. Requires synchronization from the user of the class.
 @note Not thread safe.
 */
@interface _DFImageManagerTask : NSObject

@property (nonatomic, readonly) NSUUID *taskID;
@property (nonatomic, readonly) DFImageRequest *request;
@property (nonatomic, readonly) NSDictionary /* NSUUID *handlerID : _DFImageManagerHandler */ *handlers;

@property (nonatomic, readonly) BOOL isExecuting;

/*! Returns YES if all the handlers registered with task are preheating handlers.
 */
@property (nonatomic, readonly) BOOL isPreheating;

@property (nonatomic, weak) id<_DFImageManagerTaskDelegate> delegate;

@property (nonatomic) id<DFImageFetching> fetcher;
@property (nonatomic) id<DFImageManagingCore> processingManager;

- (instancetype)initWithTaskID:(NSUUID *)taskID request:(DFImageRequest *)request NS_DESIGNATED_INITIALIZER;

- (void)resume;
- (void)cancel;
- (void)updatePriority;

- (void)addHandler:(_DFImageManagerHandler *)handler;
- (void)removeHandlerForID:(NSUUID *)handlerID;

@end

@implementation _DFImageManagerTask {
    NSMutableDictionary *_handlers;
    BOOL _isReportingProgress;
    BOOL _isFetching;
    
    // Fetch
    NSOperation *__weak _fetchOperation;
    DFImageResponse *_fetchResponse;
    
    // Processing
    NSMutableDictionary /* NSUUID *handlerID : DFImageRequestID *processingRequestID */ *_processingRequestIDs;
}

- (instancetype)initWithTaskID:(NSUUID *)taskID request:(DFImageRequest *)request {
    if (self = [super init]) {
        _taskID = taskID;
        _request = request;
        _handlers = [NSMutableDictionary new];
        _processingRequestIDs = [NSMutableDictionary new];
    }
    return self;
}

- (void)resume {
    NSAssert(_isExecuting == NO, nil);
    _isExecuting = YES;
    for (_DFImageManagerHandler *handler in [self.handlers allValues]) {
        [self _executeHandler:handler];
    }
}

- (void)addHandler:(_DFImageManagerHandler *)handler {
    _handlers[handler.requestID.handlerID] = handler;
    if (handler.request.options.progressHandler) {
        _isReportingProgress = YES;
    }
    if (self.isExecuting) {
        [self _executeHandler:handler];
    }
}

- (void)_executeHandler:(_DFImageManagerHandler *)handler {
    UIImage *cachedImage = [self _cachedImageForRequest:handler.request];
    if (cachedImage) {
        // Fulfill request with image from memory cache
        [self _didProcessResponse:[[DFImageResponse alloc] initWithImage:cachedImage] forHandler:handler];
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

- (void)removeHandlerForID:(NSUUID *)handlerID {
    [_handlers removeObjectForKey:handlerID];
    [((DFImageRequestID *)_processingRequestIDs[handlerID]) cancel];
}

#pragma mark - Fetching

- (void)_fetchImage {
    _DFImageManagerTask *__weak weakSelf = self;
    NSOperation *operation = [_fetcher startOperationWithRequest:self.request progressHandler:^(double progress) {
        [weakSelf _didUpdateFetchProgress:progress];
    } completion:^(DFImageResponse *response) {
        [weakSelf _didFetchImageWithResponse:response];
    }];
    operation.queuePriority = [self _queuePriority];
    _fetchOperation = operation;
}

- (void)_didUpdateFetchProgress:(double)progress {
    /*! Performance optimization for users that are not interested in progress reporting. Lower DFImageManager's internal queue usage.
     */
    if (_isReportingProgress) {
        [self.delegate task:self didUpdateProgress:progress];
    }
}

- (void)_didFetchImageWithResponse:(DFImageResponse *)response {
    [self.delegate task:self didReceiveResponse:_fetchResponse completion:^(BOOL shouldContinue) {
        if (shouldContinue) {
            _fetchResponse = response;
            NSAssert(self.handlers.count > 0, @"Internal inconsistency");
            for (_DFImageManagerHandler *handler in [self.handlers allValues]) {
                [self _processResponseForHandler:handler];
            }
        }
    }];
}

#pragma mark - Processing

- (void)_processResponseForHandler:(_DFImageManagerHandler *)handler {
    BOOL shouldProcessResponse = YES;
#if __has_include("DFAnimatedImage.h")
    if ([_fetchResponse.image isKindOfClass:[DFAnimatedImage class]]) {
        shouldProcessResponse = NO;
    }
#endif
    if (shouldProcessResponse && self.processingManager && _fetchResponse.image) {
        [self _processImage:_fetchResponse.image forHandler:handler completion:^(UIImage *image) {
            DFMutableImageResponse *response = [[DFMutableImageResponse alloc] initWithResponse:_fetchResponse];
            response.image = image;
            [self _didProcessResponse:response forHandler:handler];
        }];
    } else {
        if (_fetchResponse.image) {
            [self _storeImage:_fetchResponse.image forRequest:handler.request];
        }
        [self _didProcessResponse:[_fetchResponse copy] forHandler:handler];
    }
}

- (void)_processImage:(UIImage *)input forHandler:(_DFImageManagerHandler *)handler completion:(void (^)(UIImage *image))completion {
    UIImage *cachedImage = [self _cachedImageForRequest:handler.request];
    if (cachedImage) {
        completion(cachedImage);
    } else {
        DFImageRequest *processingRequest = [handler.request copy];
        processingRequest.resource = [[DFProcessingInput alloc] initWithImage:input identifier:[self.taskID UUIDString]];
        _DFImageManagerTask *__weak weakSelf = self;
        DFImageRequestID *requestID = [_processingManager requestImageForRequest:processingRequest completion:^(UIImage *processedImage, NSDictionary *info) {
            [weakSelf _storeImage:processedImage forRequest:handler.request];
            completion(processedImage);
        }];
        if (requestID) {
            _processingRequestIDs[handler.requestID.handlerID] = requestID;
        }
    }
}

- (void)_didProcessResponse:(DFImageResponse *)response forHandler:(_DFImageManagerHandler *)handler {
    [self.delegate task:self didProcessResponse:response forHandler:handler];
}

#pragma mark -

- (void)cancel {
    [_fetchOperation cancel];
    self.delegate = nil;
}

- (void)updatePriority {
    _fetchOperation.queuePriority = self._queuePriority;
}

- (NSOperationQueuePriority)_queuePriority {
    DFImageRequestPriority __block maxPriority = DFImageRequestPriorityVeryLow;
    [_handlers enumerateKeysAndObjectsUsingBlock:^(id key, _DFImageManagerHandler *handler, BOOL *stop) {
        maxPriority = MAX(handler.request.options.priority, maxPriority);
    }];
    return (NSOperationQueuePriority)maxPriority;
}

- (BOOL)isPreheating {
    for (_DFImageManagerHandler *handler in self.handlers.allValues) {
        if (![handler isKindOfClass:[_DFImageManagerPreheatHandler class]]) {
            return NO;
        }
    }
    return YES;
}

- (UIImage *)_cachedImageForRequest:(DFImageRequest *)request {
    return [self.delegate task:self cachedImageForRequest:request];
}

- (void)_storeImage:(UIImage *)image forRequest:(DFImageRequest *)request {
    [self.delegate task:self storeImage:image forRequest:request];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %p> { isExecuting = %i, isPreheating = %i }", [self class], self, self.isExecuting, self.isPreheating];
}

@end


#pragma mark - DFImageManager -

#define DFImageCacheKeyCreate(request) _DFImageKeyCreate(request, YES,  self)
#define DFImageRequestKeyCreate(request) _DFImageKeyCreate(request, NO, self)

@interface DFImageManager () <_DFImageManagerTaskDelegate, _DFImageRequestKeyDelegate>

@end

/*! Implementation details.
 - Each request+completion pair has it's own assigned DFImageRequestID
 - Multiple request+completion pairs might be handled by the same execution task (_DFImageManagerTask)
 */
@implementation DFImageManager {
    /*! Only contains not cancelled tasks. */
    NSMutableDictionary /* NSString *taskID : DFImageManagerTask */ *_tasks;
    NSMutableDictionary /* _DFImageRequestKey * : NSString *taskID */ *_taskIDs;
    dispatch_queue_t _syncQueue;
    
    struct {
        unsigned int needsToExecutePreheatRequests:1;
        unsigned int fetcherRespondsToCanonicalRequest:1;
    } _flags;
    
    /*! Read more about processing manager it initWithConfiguration: method.
     */
    id<DFImageManagingCore> _processingManager;
}

@synthesize configuration = _conf;

- (instancetype)initWithConfiguration:(DFImageManagerConfiguration *)configuration {
    if (self = [super init]) {
        NSParameterAssert(configuration);
        _conf = [configuration copy];
        
        _syncQueue = dispatch_queue_create([[NSString stringWithFormat:@"%@-queue-%p", [self class], self] UTF8String], DISPATCH_QUEUE_SERIAL);
        _tasks = [NSMutableDictionary new];
        _taskIDs = [NSMutableDictionary new];
        
        if (configuration.processor) {
            /*! DFImageManager implementation guarantees that it will create a single operation for multiple image requests that are considered equivalent by <DFImageFetching>. It does so by creating _DFImageManagerTask per request and assigning multiple handlers to the task.
             
             But, those handlers might have different image processing options like target size and content mode (or they might be the same, which is common when preheating is used). So DFImageManager also needs to guarantee that the same processing operations are executed exactly once for the handlers with the same processing options. We don't want to resize and decompress original image twice, because those are very CPU intensive operations. DFImageManager also needs to keep track of those operations and be able to cancel them. Those requirements seems very familiar - that's exactly what DFImageManager does  for the initial image requests handled by <DFImageFetching>!
             
             The solution is quite simple and elegant: use an instance of DFImageManager to manage processing operations and implement image processing using <DFImageFetching> protocol. That's exactly what DFProcessingImageManager does (and it has a simple initializer that takes <DFImageProcessing> and operation queue as a parameters). So DFImageManager uses instances of DFImageManager class in it's own implementation.
             */
            
            DFProcessingImageFetcher *processingFetcher = [[DFProcessingImageFetcher alloc] initWithProcessor:configuration.processor queue:configuration.processingQueue];
            DFImageManager *processingManager = [[DFImageManager alloc] initWithConfiguration:[DFImageManagerConfiguration configurationWithFetcher:processingFetcher]];
            processingManager.name = @"DFUnderlyingProcessingImageManager";
            _processingManager = processingManager;
        }
        
        _flags.fetcherRespondsToCanonicalRequest = (unsigned int)[_conf.fetcher respondsToSelector:@selector(canonicalRequestForRequest:)];
    }
    return self;
}

#pragma mark - <DFImageManagingCore>

- (BOOL)canHandleRequest:(DFImageRequest *)request {
    return [_conf.fetcher canHandleRequest:request];
}

#pragma mark Fetching

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
    _DFImageRequestID *requestID = [[_DFImageRequestID alloc] initWithImageManager:self]; // Represents requestID future.
    dispatch_async(_syncQueue, ^{
        NSUUID *taskID = _taskIDs[DFImageRequestKeyCreate(canonicalRequest)] ?: [NSUUID UUID];
        [requestID setTaskID:taskID handlerID:[NSUUID UUID]];
        _DFImageManagerHandler *handler = [[_DFImageManagerHandler alloc] initWithRequest:canonicalRequest requestID:requestID completion:completion];
        [self _requestImageForHandler:handler];
    });
    return requestID;
}

- (DFImageRequest *)_canonicalRequestForRequest:(DFImageRequest *)request {
    if (_flags.fetcherRespondsToCanonicalRequest) {
        return [[_conf.fetcher canonicalRequestForRequest:[request copy]] copy];
    }
    return [request copy];
}

- (void)_requestImageForHandler:(_DFImageManagerHandler *)handler {
    DFImageRequest *request = handler.request;
    _DFImageRequestID *requestID = handler.requestID;
    
    _DFImageManagerTask *task = _tasks[requestID.taskID];
    if (!task) {
        task = [[_DFImageManagerTask alloc] initWithTaskID:requestID.taskID request:request];
        task.fetcher = _conf.fetcher;
        task.processingManager = _processingManager;
        task.delegate = self;
        _tasks[requestID.taskID] = task;
        _taskIDs[DFImageRequestKeyCreate(request)] = task.taskID;
    }
    [task addHandler:handler];
    
    /*! Execute non-preheating tasks immediately. Existing preheating tasks may become non-preheating when new handlers are added.
     */
    if (!task.isExecuting && !task.isPreheating) {
        [task resume];
    } else {
        [self _setNeedsExecutePreheatingTasks];
    }
}

- (void)_setNeedsExecutePreheatingTasks {
    if (!_flags.needsToExecutePreheatRequests) {
        _flags.needsToExecutePreheatRequests = YES;
        /*! Delays serves double purpose:
         - Image manager won't start executing preheating requests in case you are about to add normal (non-preheating) right after adding preheating ones.
         - Image manager won't execute relatively -_executePreheatingTasksIfNecesary method too often.
         */
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), _syncQueue, ^{
            [self _executePreheatingTasksIfNecesary];
            _flags.needsToExecutePreheatRequests = NO;
        });
    }
}

/*! Image manager will not execute preheating tasks until there is a least one normal executing tasks. There number of concurrent preheating tasks is limited.
 */
- (void)_executePreheatingTasksIfNecesary {
    NSArray *executingTasks = [_tasks.allValues filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isExecuting = YES"]];
    if (executingTasks.count < _conf.maximumConcurrentPreheatingRequests) {
        BOOL isExecutingNormalTasks = NO;
        for (_DFImageManagerTask *task in executingTasks) {
            if (!task.isPreheating) {
                isExecutingNormalTasks = YES;
                break;
            }
        }
        if (!isExecutingNormalTasks) {
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
}

- (void)_removeTask:(_DFImageManagerTask *)task {
    [_taskIDs removeObjectForKey:DFImageRequestKeyCreate(task.request)];
    [_tasks removeObjectForKey:task.taskID];
    [self _setNeedsExecutePreheatingTasks];
}

#pragma mark - <_DFImageManagerTaskDelegate>

- (void)task:(_DFImageManagerTask *)task didReceiveResponse:(DFImageResponse *)response completion:(void (^)(BOOL))completion {
    dispatch_async(_syncQueue, ^{
        completion(_tasks[task.taskID] == task);
    });
}

- (void)task:(_DFImageManagerTask *)task didUpdateProgress:(double)progress {
    dispatch_async(_syncQueue, ^{
        if (_tasks[task.taskID] == task) {
            [task.handlers enumerateKeysAndObjectsUsingBlock:^(id key, _DFImageManagerHandler *handler, BOOL *stop) {
                void (^progressHandler)(double) = handler.request.options.progressHandler;
                if (progressHandler) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (progressHandler) {
                            progressHandler(progress);
                        }
                    });
                }
            }];
        }
    });
}

- (void)task:(_DFImageManagerTask *)task didProcessResponse:(DFImageResponse *)response forHandler:(_DFImageManagerHandler *)handler {
    dispatch_async(_syncQueue, ^{
        if (_tasks[task.taskID] == task) {
            [task removeHandlerForID:handler.requestID.handlerID];
            if (task.handlers.count == 0) {
                [self _removeTask:task];
            }
            NSMutableDictionary *mutableInfo = [NSMutableDictionary dictionaryWithDictionary:[self _infoFromResponse:response]];
            mutableInfo[DFImageInfoRequestIDKey] = handler.requestID;
            dispatch_async(dispatch_get_main_queue(), ^{
                if (handler.completion) {
                    handler.completion(response.image, mutableInfo);
                }
            });
        }
    });
}

- (NSDictionary *)_infoFromResponse:(DFImageResponse *)response {
    NSMutableDictionary *info = [NSMutableDictionary new];
    if (response.error) {
        info[DFImageInfoErrorKey] = response.error;
    }
    [info addEntriesFromDictionary:response.userInfo];
    return [info copy];
}

- (UIImage *)task:(_DFImageManagerTask *)task cachedImageForRequest:(DFImageRequest *)request {
    return [self _cachedImageForRequest:request];
}

- (UIImage *)_cachedImageForRequest:(DFImageRequest *)request {
    if (request.options.memoryCachePolicy == DFImageRequestCachePolicyReloadIgnoringCache) {
        return nil;
    }
    DFCachedImage *cachedImage = [_conf.cache cachedImageForKey:DFImageCacheKeyCreate(request)];
    return cachedImage.image;
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

#pragma mark Cancel

- (void)cancelRequestWithID:(DFImageRequestID *)requestID {
    if (requestID) {
        dispatch_async(_syncQueue, ^{
            [self _cancelRequestWithID:(_DFImageRequestID *)requestID];
        });
    }
}

- (void)_cancelRequestWithID:(_DFImageRequestID *)requestID {
    _DFImageManagerTask *task = _tasks[requestID.taskID];
    if (task) {
        [task removeHandlerForID:requestID.handlerID];
        if (task.handlers.count == 0) {
            [task cancel];
            [self _removeTask:task];
        } else {
            [task updatePriority];
        }
    }
}

#pragma mark Priorities

- (void)setPriority:(DFImageRequestPriority)priority forRequestWithID:(_DFImageRequestID *)requestID {
    if (requestID) {
        dispatch_async(_syncQueue, ^{
            _DFImageManagerTask *task = _tasks[requestID.taskID];
            _DFImageManagerHandler *handler = task.handlers[requestID.handlerID];
            if (handler.request.options.priority != priority) {
                handler.request.options.priority = priority;
                [task updatePriority];
            }
        });
    }
}

#pragma mark Preheating

- (void)startPreheatingImagesForRequests:(NSArray *)requests {
    if (requests.count > 0) {
        dispatch_async(_syncQueue, ^{
            NSMutableArray *canonicalRequests = [[NSMutableArray alloc] initWithCapacity:requests.count];
            for (DFImageRequest *request in requests) {
                [canonicalRequests addObject:[self _canonicalRequestForRequest:request]];
            }
            [self _startPreheatingImageForRequests:canonicalRequests];
        });
    }
}

- (void)_startPreheatingImageForRequests:(NSArray *)requests {
    for (DFImageRequest *request in requests) {
        NSUUID *taskID = _taskIDs[DFImageRequestKeyCreate(request)];
        _DFImageManagerTask *task = _tasks[taskID];
        if (task == nil || ![self _preheatingHandlerForRequest:request task:task]) {
            _DFImageRequestID *requestID = [[_DFImageRequestID alloc] initWithImageManager:self];
            [requestID setTaskID:taskID ?: [NSUUID UUID] handlerID:[NSUUID UUID]];
            _DFImageManagerPreheatHandler *handler = [[_DFImageManagerPreheatHandler alloc] initWithRequest:request requestID:requestID completion:nil];
            [self _requestImageForHandler:handler];
        }
    }
}

- (void)stopPreheatingImagesForRequests:(NSArray *)requests {
    if (requests.count > 0) {
        dispatch_async(_syncQueue, ^{
            NSMutableArray *canonicalRequests = [[NSMutableArray alloc] initWithCapacity:requests.count];
            for (DFImageRequest *request in requests) {
                [canonicalRequests addObject:[self _canonicalRequestForRequest:request]];
            }
            [self _stopPreheatingImagesForRequests:canonicalRequests];
        });
    }
}

- (void)_stopPreheatingImagesForRequests:(NSArray *)requests {
    for (DFImageRequest *request in requests) {
        NSUUID *taskID = _taskIDs[DFImageRequestKeyCreate(request)];
        _DFImageManagerTask *task = _tasks[taskID];
        _DFImageManagerHandler *handler = [self _preheatingHandlerForRequest:request task:task];
        if (handler) {
            [self _cancelRequestWithID:handler.requestID];
        }
    }
}

- (void)stopPreheatingImagesForAllRequests {
    dispatch_async(_syncQueue, ^{
        NSMutableArray *requestIDs = [NSMutableArray new];
        for (_DFImageManagerTask *task in _tasks.allValues) {
            for (_DFImageManagerHandler *handler in task.handlers.allValues) {
                if ([handler isKindOfClass:[_DFImageManagerPreheatHandler class]]) {
                    [requestIDs addObject:handler.requestID];
                }
            }
        }
        for (_DFImageRequestID *requestID in requestIDs) {
            [self _cancelRequestWithID:requestID];
        }
    });
}

- (_DFImageManagerPreheatHandler *)_preheatingHandlerForRequest:(DFImageRequest *)request task:(_DFImageManagerTask *)task {
    for (_DFImageManagerHandler *handler in task.handlers.allValues) {
        if ([handler isKindOfClass:[_DFImageManagerPreheatHandler class]]) {
            if (_conf.processor == nil || [_conf.processor isProcessingForRequestEquivalent:handler.request toRequest:request]) {
                return (_DFImageManagerPreheatHandler *)handler;
            }
        }
    }
    return nil;
}

#pragma mark - Dependency Injectors

static id<DFImageManaging> _sharedManager;

+ (id<DFImageManaging>)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!_sharedManager) {
            _sharedManager = [self createDefaultManager];
        }
    });
    return _sharedManager;
}

+ (void)setSharedManager:(id<DFImageManaging>)manager {
    _sharedManager = manager;
}

#pragma mark -

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %p> { name = %@ }", [self class], self, self.name];
}

@end


#pragma mark - DFImageManager (Convenience) <DFImageManaging> -

@implementation DFImageManager (Convenience)

- (DFImageRequestID *)requestImageForResource:(id)resource targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options completion:(void (^)(UIImage *, NSDictionary *))completion {
    return [self requestImageForRequest:[[DFImageRequest alloc] initWithResource:resource targetSize:targetSize contentMode:contentMode options:options] completion:completion];
}

- (DFImageRequestID *)requestImageForResource:(id)resource completion:(void (^)(UIImage *, NSDictionary *))completion {
    return [self requestImageForResource:resource targetSize:DFImageMaximumSize contentMode:DFImageContentModeAspectFill options:nil completion:completion];
}

- (void)startPreheatingImageForResources:(NSArray *)resources targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options {
    [self startPreheatingImagesForRequests:[self _requestsForResources:resources targetSize:targetSize contentMode:contentMode options:options]];
}

- (void)stopPreheatingImagesForResources:(NSArray *)resources targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options {
    [self stopPreheatingImagesForRequests:[self _requestsForResources:resources targetSize:targetSize contentMode:contentMode options:options]];
}

- (NSArray *)_requestsForResources:(NSArray *)resources targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options {
    NSMutableArray *requests = [NSMutableArray new];
    for (id resource in resources) {
        [requests addObject:[[DFImageRequest alloc] initWithResource:resource targetSize:targetSize contentMode:contentMode options:options]];
    }
    return [requests copy];
}

@end
