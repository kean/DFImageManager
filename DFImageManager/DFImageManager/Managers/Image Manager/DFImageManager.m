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

#import "DFImageManager.h"
#import "DFImageManagerDefines.h"
#import "DFImageRequest.h"
#import "DFImageRequestID+Protected.h"
#import "DFImageRequestID.h"
#import "DFImageRequestOptions.h"
#import "DFImageResponse.h"
#import <UIKit/UIKit.h>

static NSString *const _kPreheatHandlerID = @"_df_preheat";


#pragma mark - _DFImageRequestHandler -

@interface _DFImageRequestHandler : NSObject

@property (nonatomic, readonly) DFImageRequest *request;
@property (nonatomic, readonly) DFImageRequestID *requestID;
@property (nonatomic, copy, readonly) DFImageRequestCompletion completion;

- (instancetype)initWithRequest:(DFImageRequest *)request requestID:(DFImageRequestID *)requestID completion:(DFImageRequestCompletion)completion NS_DESIGNATED_INITIALIZER;

@end

@implementation _DFImageRequestHandler

- (instancetype)initWithRequest:(DFImageRequest *)request requestID:(DFImageRequestID *)requestID completion:(DFImageRequestCompletion)completion {
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



#pragma mark - _DFImageManagerTask -

@class _DFImageManagerTask;

@protocol _DFImageManagerTaskDelegate <NSObject>

/*! Gets called when task fetches image. Task may skip this method if it already has processed response for all handlers.
 */
- (void)task:(_DFImageManagerTask *)task didReceiveResponse:(DFImageResponse *)response completion:(void (^)(BOOL shouldContinue))completion;

/*! Gets called when task retreives processed response.
 */
- (void)task:(_DFImageManagerTask *)task didProcessResponse:(DFImageResponse *)response forHandler:(_DFImageRequestHandler *)handler;

@end


/*! Implements the entire flow of retrieving, processing and caching images. Requires synchronization from the user of the class.
 @note Not thread safe.
 */
@interface _DFImageManagerTask : NSObject

@property (nonatomic, readonly) NSString *ECID;
@property (nonatomic, readonly) DFImageRequest *request;
@property (nonatomic, readonly) NSDictionary *handlers;

@property (nonatomic, readonly) BOOL isExecuting;
@property (nonatomic, readonly) BOOL isCancelled;

/*! Returns YES if all the handlers registered with task are preheating handlers.
 */
@property (nonatomic, readonly) BOOL isPreheating;

@property (nonatomic, weak) id<_DFImageManagerTaskDelegate> delegate;

@property (nonatomic) id<DFImageFetcher> fetcher;
@property (nonatomic) id<DFImageProcessor> processor;
@property (nonatomic) id<DFImageCache> cache;

- (instancetype)initWithECID:(NSString *)ECID request:(DFImageRequest *)request NS_DESIGNATED_INITIALIZER;

- (void)resume;
- (void)cancel;
- (void)updatePriority;

- (void)addHandler:(_DFImageRequestHandler *)handler;
- (void)removeHandlerForID:(NSString *)handlerID;

@end

@implementation _DFImageManagerTask {
    NSMutableDictionary *_handlers;
    DFImageResponse *_response;
    NSOperation<DFImageManagerOperation> *__weak _operation;
}

- (instancetype)initWithECID:(NSString *)ECID request:(DFImageRequest *)request {
    if (self = [super init]) {
        _ECID = ECID;
        _request = request;
        _handlers = [NSMutableDictionary new];
    }
    return self;
}

- (void)resume {
    NSAssert(_isExecuting == NO, nil);
    _isExecuting = YES;
    
    for (_DFImageRequestHandler *handler in [self.handlers allValues]) {
        UIImage *image = [_cache cachedImageForRequest:handler.request];
        if (image != nil) {
            // Fullfill request with image from memory cache
            [self _didProcessResponse:[[DFImageResponse alloc] initWithImage:image] forHandler:handler];
        }
    }
    // Start fetching if not all requests were fulfilled by memory cache
    if (self.handlers.count > 0) {
        [self _fetchImage];
    }
}

- (void)addHandler:(_DFImageRequestHandler *)handler {
    _handlers[handler.requestID.handlerID] = handler;
    if (self.isExecuting) {
        UIImage *image = [_cache cachedImageForRequest:handler.request];
        if (image != nil) {
            // Fullfill request with image from memory cache
            [self _didProcessResponse:[[DFImageResponse alloc] initWithImage:image] forHandler:handler];
        } else if (_response != nil) {
            // Start image processing if task already has original image
            [self _processResponseForHandler:handler];
        } else {
            // Wait until task receives requested image
        }
    } else {
        // Wait until task is resumed
    }
}

- (void)removeHandlerForID:(NSString *)handlerID {
    [_handlers removeObjectForKey:handlerID];
}

- (void)_fetchImage {
    NSOperation<DFImageManagerOperation> *operation = [_fetcher createOperationForRequest:self.request];
    NSParameterAssert(operation);
    
    _DFImageManagerTask *__weak weakSelf = self;
    NSOperation<DFImageManagerOperation> *__weak weakOp = operation;
    [operation setCompletionBlock:^{
        [weakSelf _didFetchImageWithOperation:weakOp];
    }];
    operation.queuePriority = self._queuePriority;
    _operation = operation;
    [_fetcher enqueueOperation:operation];
}

- (void)_didFetchImageWithOperation:(NSOperation<DFImageManagerOperation> *)operation {
    _response = [operation imageResponse];
    [self.delegate task:self didReceiveResponse:_response completion:^(BOOL shouldContinue) {
        if (shouldContinue) {
            NSAssert(self.handlers.count > 0, @"Internal inconsistency");
            for (_DFImageRequestHandler *handler in [self.handlers allValues]) {
                [self _processResponseForHandler:handler];
            }
        }
    }];
}

- (void)_processResponseForHandler:(_DFImageRequestHandler *)handler {
    [self _processImage:_response.image forHandler:handler completion:^(UIImage *image) {
        DFMutableImageResponse *response = [[DFMutableImageResponse alloc] initWithResponse:_response];
        response.image = image;
        [self _didProcessResponse:response forHandler:handler];
    }];
}

- (void)_processImage:(UIImage *)input forHandler:(_DFImageRequestHandler *)handler completion:(void (^)(UIImage *image))completion {
    if (_processor != nil && input != nil) {
        UIImage *cachedImage = [_cache cachedImageForRequest:handler.request];
        if (cachedImage != nil) {
            completion(cachedImage);
        } else {
            [_processor processImage:input forRequest:handler.request completion:^(UIImage *image) {
                [_cache storeImage:image forRequest:handler.request];
                completion(image);
            }];
        }
    } else {
        [_cache storeImage:input forRequest:handler.request];
        completion(input);
    }
}

- (void)_didProcessResponse:(DFImageResponse *)response forHandler:(_DFImageRequestHandler *)handler {
    [self.delegate task:self didProcessResponse:response forHandler:handler];
}

- (void)cancel {
    _isCancelled = YES;
    [_operation cancel];
    self.delegate = nil;
}

- (void)updatePriority {
    _operation.queuePriority = self._queuePriority;
}

- (NSOperationQueuePriority)_queuePriority {
    DFImageRequestPriority __block maxPriority = DFImageRequestPriorityVeryLow;
    [_handlers enumerateKeysAndObjectsUsingBlock:^(id key, _DFImageRequestHandler *handler, BOOL *stop) {
        maxPriority = MAX(handler.request.options.priority, maxPriority);
    }];
    return (NSOperationQueuePriority)maxPriority;
}

- (BOOL)isPreheating {
    for (NSString *handlerID in [self.handlers allKeys]) {
        if (![handlerID isEqualToString:_kPreheatHandlerID]) {
            return NO;
        }
    }
    return YES;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %p> { isExecuting = %i, isCancelled = %i, isPreheating = %i }", [self class], self, self.isExecuting, self.isCancelled, self.isPreheating];
}

@end


#pragma mark - DFImageManager -

@interface DFImageManager () <_DFImageManagerTaskDelegate>

@end

/*! Implementation details.
 - Each request+completion pair has it's own assigned DFImageRequestID
 - Multiple request+completion pairs might be handled by the same execution task (DFImageManagerTask)
 */
@implementation DFImageManager {
    /*! Only contains not cancelled tasks. */
    NSMutableDictionary /* NSString *ECID : DFImageManagerTask */ *_tasks;
    dispatch_queue_t _syncQueue;
}

@synthesize configuration = _conf;

+ (void)initialize {
    [self setSharedManager:[self defaultManager]];
}

- (instancetype)initWithConfiguration:(DFImageManagerConfiguration *)configuration {
    if (self = [super init]) {
        NSParameterAssert(configuration);
        _conf = [configuration copy];
        
        _syncQueue = dispatch_queue_create([[NSString stringWithFormat:@"%@-queue-%p", [self class], self] UTF8String], DISPATCH_QUEUE_SERIAL);
        _tasks = [NSMutableDictionary new];
    }
    return self;
}

#pragma mark - <DFCoreImageManager>

- (BOOL)canHandleRequest:(DFImageRequest *)request {
    return [_conf.fetcher canHandleRequest:request];
}

#pragma mark Fetching

- (DFImageRequestID *)requestImageForRequest:(DFImageRequest *)request completion:(DFImageRequestCompletion)completion {
    request = [request copy];
    DFImageRequestID *requestID = [[DFImageRequestID alloc] initWithImageManager:self]; // Represents requestID future.
    dispatch_async(_syncQueue, ^{
        NSString *ECID = [_conf.fetcher executionContextIDForRequest:request];
        [requestID setECID:ECID handlerID:[[NSUUID UUID] UUIDString]];
        [self _requestImageForRequest:request requestID:requestID completion:completion];
    });
    return requestID;
}

- (void)_requestImageForRequest:(DFImageRequest *)request requestID:(DFImageRequestID *)requestID completion:(DFImageRequestCompletion)completion {
    _DFImageRequestHandler *handler = [[_DFImageRequestHandler alloc] initWithRequest:request requestID:requestID completion:completion];
    _DFImageManagerTask *task = _tasks[requestID.ECID];
    if (!task) {
        task = [[_DFImageManagerTask alloc] initWithECID:requestID.ECID request:request];
        task.fetcher = _conf.fetcher;
        task.processor = _conf.processor;
        task.cache = _conf.cache;
        task.delegate = self;
        _tasks[requestID.ECID] = task;
    }
    [task addHandler:handler];
    
    /*! Execute non-preheating tasks immediately. Existing preheating tasks may become non-preheating when new handlers are added.
     */
    if (!task.isExecuting && !task.isPreheating) {
        [task resume];
    } else {
        [self _executePreheatingTasksIfNecesary];
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

- (void)_removeTaskForECID:(NSString *)ECID {
    [_tasks removeObjectForKey:ECID];
    [self _executePreheatingTasksIfNecesary];
}

#pragma mark - <_DFImageManagerTaskDelegate>

- (void)task:(_DFImageManagerTask *)task didReceiveResponse:(DFImageResponse *)response completion:(void (^)(BOOL))completion {
    dispatch_async(_syncQueue, ^{
        completion(_tasks[task.ECID] == task);
    });
}

- (void)task:(_DFImageManagerTask *)task didProcessResponse:(DFImageResponse *)response forHandler:(_DFImageRequestHandler *)handler {
    dispatch_async(_syncQueue, ^{
        if (_tasks[task.ECID] == task) {
            [task removeHandlerForID:handler.requestID.handlerID];
            if (task.handlers.count == 0) {
                [self _removeTaskForECID:task.ECID];
            }
            NSMutableDictionary *mutableInfo = [NSMutableDictionary dictionaryWithDictionary:[self _infoFromResponse:response]];
            mutableInfo[DFImageInfoRequestIDKey] = handler.requestID;
            dispatch_async(dispatch_get_main_queue(), ^{
                if (handler.completion != nil) {
                    handler.completion(response.image, mutableInfo);
                }
            });
        }
    });
}

- (NSDictionary *)_infoFromResponse:(DFImageResponse *)response {
    NSMutableDictionary *info = [NSMutableDictionary new];
    if (response.error != nil) {
        info[DFImageInfoErrorKey] = response.error;
    }
    [info addEntriesFromDictionary:response.userInfo];
    return [info copy];
}

#pragma mark Cancel

- (void)cancelRequestWithID:(DFImageRequestID *)requestID {
    if (requestID != nil) {
        dispatch_async(_syncQueue, ^{
            [self _cancelRequestWithID:requestID];
        });
    }
}

- (void)_cancelRequestWithID:(DFImageRequestID *)requestID {
    _DFImageManagerTask *task = _tasks[requestID.ECID];
    if (task != nil) {
        [task removeHandlerForID:requestID.handlerID];
        if (task.handlers.count == 0) {
            [task cancel];
            [self _removeTaskForECID:requestID.ECID];
        } else {
            [task updatePriority];
        }
    }
}

#pragma mark Priorities

- (void)setPriority:(DFImageRequestPriority)priority forRequestWithID:(DFImageRequestID *)requestID {
    if (requestID != nil) {
        dispatch_async(_syncQueue, ^{
            _DFImageManagerTask *task = _tasks[requestID.ECID];
            _DFImageRequestHandler *handler = task.handlers[requestID.handlerID];
            if (handler.request.options.priority != priority) {
                handler.request.options.priority = priority;
                [task updatePriority];
            }
        });
    }
}

#pragma mark Preheating

- (void)startPreheatingImagesForRequests:(NSArray *)requests {
    requests = [[NSArray alloc] initWithArray:requests copyItems:YES];
    if (requests.count) {
        dispatch_async(_syncQueue, ^{
            [self _startPreheatingImageForRequests:requests];
        });
    }
}

- (void)_startPreheatingImageForRequests:(NSArray *)requests {
    for (DFImageRequest *request in requests) {
        DFImageRequestID *requestID = [self _preheatingIDForRequest:request];
        _DFImageManagerTask *task = _tasks[requestID.ECID];
        _DFImageRequestHandler *handler = task.handlers[requestID.handlerID];
        if (!handler) {
            [self _requestImageForRequest:request requestID:requestID completion:nil];
        }
    }
}

- (void)stopPreheatingImagesForRequests:(NSArray *)requests {
    requests = [[NSArray alloc] initWithArray:requests copyItems:YES];
    if (requests.count) {
        dispatch_async(_syncQueue, ^{
            [self _stopPreheatingImagesForRequests:requests];
        });
    }
}

- (void)_stopPreheatingImagesForRequests:(NSArray *)requests {
    for (DFImageRequest *request in requests) {
        DFImageRequestID *requestID = [self _preheatingIDForRequest:request];
        [self _cancelRequestWithID:requestID];
    }
}

- (DFImageRequestID *)_preheatingIDForRequest:(DFImageRequest *)request {
    NSString *ECID = [_conf.fetcher executionContextIDForRequest:request];
    return [DFImageRequestID requestIDWithImageManager:self ECID:ECID handlerID:_kPreheatHandlerID];
}

- (void)stopPreheatingImagesForAllRequests {
    dispatch_async(_syncQueue, ^{
        [_tasks enumerateKeysAndObjectsUsingBlock:^(NSString *ECID, _DFImageManagerTask *task, BOOL *stop) {
            NSMutableArray *requestIDs = [NSMutableArray new];
            [task.handlers enumerateKeysAndObjectsUsingBlock:^(NSString *handlerID, _DFImageRequestHandler *handler, BOOL *stop_inner) {
                if ([handlerID isEqualToString:_kPreheatHandlerID]) {
                    [requestIDs addObject:[DFImageRequestID requestIDWithImageManager:self ECID:ECID handlerID:handlerID]];
                }
            }];
            for (DFImageRequestID *requestID in requestIDs) {
                [self _cancelRequestWithID:requestID];
            }
        }];
    });
}

#pragma mark - <DFImageManager>

- (DFImageRequestID *)requestImageForAsset:(id)asset targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options completion:(void (^)(UIImage *, NSDictionary *))completion {
    return [self requestImageForRequest:[[DFImageRequest alloc] initWithAsset:asset targetSize:targetSize contentMode:contentMode options:options] completion:completion];
}

- (void)startPreheatingImageForAssets:(NSArray *)assets targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options {
    [self startPreheatingImagesForRequests:[self _requestsForAssets:assets targetSize:targetSize contentMode:contentMode options:options]];
}

- (void)stopPreheatingImagesForAssets:(NSArray *)assets targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options {
    [self stopPreheatingImagesForRequests:[self _requestsForAssets:assets targetSize:targetSize contentMode:contentMode options:options]];
}

- (NSArray *)_requestsForAssets:(NSArray *)assets targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options {
    NSMutableArray *requests = [NSMutableArray new];
    for (id asset in assets) {
        [requests addObject:[[DFImageRequest alloc] initWithAsset:asset targetSize:targetSize contentMode:contentMode options:options]];
    }
    return [requests copy];
}

#pragma mark - Dependency Injectors

static id<DFImageManager> _sharedManager;

+ (id<DFImageManager>)sharedManager {
    @synchronized(self) {
        return _sharedManager;
    }
}

+ (void)setSharedManager:(id<DFImageManager>)manager {
    @synchronized(self) {
        _sharedManager = manager;
    }
}

@end
