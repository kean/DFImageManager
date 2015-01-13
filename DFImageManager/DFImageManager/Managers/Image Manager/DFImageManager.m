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
    return [NSString stringWithFormat:@"<%@ %p> { request = %@, requestID = %@ }", [self class], self, self.request, self.requestID];
}

@end



#pragma mark - _DFImageRequestPreheatingHandler -

static NSString *const _kPreheatHandlerID = @"_df_preheat";

@interface _DFImageRequestPreheatingHandler : _DFImageRequestHandler

@end

@implementation _DFImageRequestPreheatingHandler

- (NSUInteger)hash {
    return [self.requestID.ECID hash];
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }
    _DFImageRequestPreheatingHandler *other = object;
    return [other.requestID.ECID isEqualToString:self.requestID.ECID];
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
 */
@interface _DFImageManagerTask : NSObject

@property (nonatomic, readonly) NSString *ECID;
@property (nonatomic, readonly) DFImageRequest *request;
@property (nonatomic, readonly) NSDictionary *handlers;

@property (nonatomic, readonly) BOOL isExecuting;
@property (nonatomic, readonly) BOOL isCancelled;

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

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %p> { request = %@, operation = %@, handlers = %@ }", [self class], self, self.request, _operation, self.handlers];
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
    NSMutableDictionary /* NSString *ECID : DFImageManagerTask */ *_tasks;
    NSMutableOrderedSet /* _DFPreheatingHandler */ *_pendingPreheatingHandlers;
    
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
        _pendingPreheatingHandlers = [NSMutableOrderedSet new];
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
        _DFImageRequestHandler *handler = [[_DFImageRequestHandler alloc] initWithRequest:request requestID:requestID completion:completion];
        [self _requestImageForHandler:handler];
    });
    return requestID;
}

- (void)_requestImageForHandler:(_DFImageRequestHandler *)handler {
    DFImageRequest *request = handler.request;
    DFImageRequestID *requestID = handler.requestID;
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
    if (!task.isExecuting) {
        [task resume];
    }
}

- (void)_removeTaskForECID:(NSString *)ECID {
    [_tasks removeObjectForKey:ECID];
    [self _startExecutingPreheatingRequestsIfNecessary];
}

#pragma mark - <_DFImageManagerTaskDelegate>

- (void)task:(_DFImageManagerTask *)task didReceiveResponse:(DFImageResponse *)response completion:(void (^)(BOOL))completion {
    dispatch_async(_syncQueue, ^{
        completion(!task.isCancelled);
    });
}

- (void)task:(_DFImageManagerTask *)task didProcessResponse:(DFImageResponse *)response forHandler:(_DFImageRequestHandler *)handler {
    dispatch_async(_syncQueue, ^{
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
        _DFImageRequestPreheatingHandler *handler = [[_DFImageRequestPreheatingHandler alloc] initWithRequest:request requestID:requestID completion:nil];
        [_pendingPreheatingHandlers addObject:handler];
        [self _startExecutingPreheatingRequestsIfNecessary];
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
        _DFImageRequestPreheatingHandler *handler = [[_DFImageRequestPreheatingHandler alloc] initWithRequest:request requestID:requestID completion:nil];
        [_pendingPreheatingHandlers removeObject:handler];
        [self _cancelRequestWithID:requestID];
    }
}

- (DFImageRequestID *)_preheatingIDForRequest:(DFImageRequest *)request {
    NSString *ECID = [_conf.fetcher executionContextIDForRequest:request];
    return [DFImageRequestID requestIDWithImageManager:self ECID:ECID handlerID:_kPreheatHandlerID];
}

- (void)stopPreheatingImagesForAllRequests {
    dispatch_async(_syncQueue, ^{
        for (_DFImageRequestPreheatingHandler *handler in _pendingPreheatingHandlers) {
            [self _cancelRequestWithID:handler.requestID];
        }
        [_pendingPreheatingHandlers removeAllObjects];
    });
}

- (void)_startExecutingPreheatingRequestsIfNecessary {
    if (_tasks.count < _conf.maximumConcurrentPreheatingRequests) {
        _DFImageRequestPreheatingHandler *handler = [_pendingPreheatingHandlers firstObject];
        if (handler != nil) {
            [_pendingPreheatingHandlers removeObject:handler];
            [self _requestImageForHandler:handler];
        }
    }
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
