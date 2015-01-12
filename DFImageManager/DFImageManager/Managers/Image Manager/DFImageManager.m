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


@interface _DFRequestHandler : NSObject

@property (nonatomic, readonly) DFImageRequest *request;
@property (nonatomic, readonly) DFImageRequestID *requestID;
@property (nonatomic, copy, readonly) DFImageRequestCompletion completion;

- (instancetype)initWithRequest:(DFImageRequest *)request requestID:(DFImageRequestID *)requestID completion:(DFImageRequestCompletion)completion NS_DESIGNATED_INITIALIZER;

@end

@implementation _DFRequestHandler

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


@interface _DFRequestExecutionContext : NSObject

@property (nonatomic, readonly) NSString *ECID;
@property (nonatomic, readonly) DFImageRequest *request;
@property (nonatomic, readonly) NSMutableDictionary *handlers;

@property (nonatomic, weak) NSOperation<DFImageManagerOperation> *operation;
@property (nonatomic) DFImageResponse *response;

- (instancetype)initWithECID:(NSString *)ECID request:(DFImageRequest *)request NS_DESIGNATED_INITIALIZER;

/*! Returns maximum queue priority from handlers.
 */
@property (nonatomic, readonly) NSOperationQueuePriority queuePriority;

@end

@implementation _DFRequestExecutionContext

- (instancetype)initWithECID:(NSString *)ECID request:(DFImageRequest *)request {
    if (self = [super init]) {
        _ECID = ECID;
        _request = request;
        _handlers = [NSMutableDictionary new];
    }
    return self;
}

- (NSOperationQueuePriority)queuePriority {
    DFImageRequestPriority __block maxPriority = DFImageRequestPriorityVeryLow;
    [_handlers enumerateKeysAndObjectsUsingBlock:^(id key, _DFRequestHandler *handler, BOOL *stop) {
        maxPriority = MAX(handler.request.options.priority, maxPriority);
    }];
    return (NSOperationQueuePriority)maxPriority;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %p> { request = %@, operation = %@, handlers = %@ }", [self class], self, self.request, self.operation, self.handlers];
}

@end


@interface _DFPreheatingHandler : _DFRequestHandler

@end

@implementation _DFPreheatingHandler

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
    _DFPreheatingHandler *other = object;
    return [other.requestID.ECID isEqualToString:self.requestID.ECID];
}

@end


/*! Implementation details.
 - Each request+completion pair has it's own assigned DFImageRequestID
 - Multiple request+completion pairs might be handled by the same execution context (_DFRequestExecutionContext)
 */
@implementation DFImageManager {
    NSMutableDictionary /* NSString *ECID : _DFRequestExecutionContext */ *_executionContexts;
    NSMutableOrderedSet /* _DFPreheatingHandler */ *_preheatingHandlers;
    
    dispatch_queue_t _syncQueue;
}

+ (void)initialize {
    [self setSharedManager:[self defaultManager]];
}

- (instancetype)initWithImageFetcher:(id<DFImageFetcher>)fetcher processor:(id<DFImageProcessor>)processor cache:(id<DFImageCache>)cache {
    if (self = [super init]) {
        _fetcher = fetcher;
        _processor = processor;
        _cache = cache;
        
        _syncQueue = dispatch_queue_create([[NSString stringWithFormat:@"%@-queue-%p", [self class], self] UTF8String], DISPATCH_QUEUE_SERIAL);
        _executionContexts = [NSMutableDictionary new];
        _preheatingHandlers = [NSMutableOrderedSet new];
    }
    return self;
}

#pragma mark - <DFCoreImageManager>

- (BOOL)canHandleRequest:(DFImageRequest *)request {
    return [_fetcher canHandleRequest:request];
}

#pragma mark Fetching

- (DFImageRequestID *)requestImageForRequest:(DFImageRequest *)request completion:(DFImageRequestCompletion)completion {
    request = [request copy];
    DFImageRequestID *requestID = [[DFImageRequestID alloc] initWithImageManager:self]; // Represents requestID future.
    dispatch_async(_syncQueue, ^{
        NSString *ECID = [_fetcher executionContextIDForRequest:request];
        [requestID setECID:ECID handlerID:[[NSUUID UUID] UUIDString]];
        _DFRequestHandler *handler = [[_DFRequestHandler alloc] initWithRequest:request requestID:requestID completion:completion];
        [self _requestImageForHandler:handler];
    });
    return requestID;
}

- (void)_requestImageForHandler:(_DFRequestHandler *)handler {
    DFImageRequest *request = handler.request;
    DFImageRequestID *requestID = handler.requestID;
    
    // TODO: Too complicated and error-prone, fix it.
    if (_cache != nil) {
        UIImage *image = [_cache cachedImageForRequest:request];
        if (image != nil) {
            [self _didCompleteRequestWithImage:image info:nil handler:handler];
            return;
        }
    }
    
    _DFRequestExecutionContext *context = _executionContexts[requestID.ECID];
    if (!context) {
        context = [[_DFRequestExecutionContext alloc] initWithECID:requestID.ECID request:request];
        context.handlers[requestID.handlerID] = handler;
        _executionContexts[requestID.ECID] = context;
        [self _requestImageForContext:context];
    } else {
        context.handlers[requestID.handlerID] = handler;
        if (context.response != nil) {
            [self _processResponseForContext:context handler:handler];
        }
    }
}

- (void)_requestImageForContext:(_DFRequestExecutionContext *)context {
    NSOperation<DFImageManagerOperation> *operation = [_fetcher createOperationForRequest:context.request];
    if (operation != nil) {
        DFImageManager *__weak weakSelf = self;
        NSOperation<DFImageManagerOperation> *__weak weakOp = operation;
        [operation setCompletionBlock:^{
            [weakSelf _didCompleteOperation:weakOp context:context];
        }];
        operation.queuePriority = context.queuePriority;
        context.operation = operation;
        [_fetcher enqueueOperation:operation];
    } else {
        [self _didCompleteRequestForContext:context];
    }
}

- (void)_didCompleteOperation:(NSOperation<DFImageManagerOperation> *)operation context:(_DFRequestExecutionContext *)context {
    dispatch_async(_syncQueue, ^{
        if (_executionContexts[context.ECID] == context) { // context not cancelled
            context.response = [operation imageResponse];
            [self _didCompleteRequestForContext:context];
        }
    });
}

- (void)_didCompleteRequestForContext:(_DFRequestExecutionContext *)context {
    NSAssert(context.handlers.count > 0, @"Invalid context");
    for (_DFRequestHandler *handler in [context.handlers allValues]) {
        [self _processResponseForContext:context handler:handler];
    }
    if (context.response.error != nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([_fetcher respondsToSelector:@selector(imageManager:didEncounterError:)]) {
                [_fetcher imageManager:self didEncounterError:context.response.error];
            }
        });
    }
}

- (void)_processResponseForContext:(_DFRequestExecutionContext *)context handler:(_DFRequestHandler *)handler {
    [self _processImage:context.response.image forHandler:handler completion:^(UIImage *image) {
        dispatch_async(_syncQueue, ^{
            [context.handlers removeObjectForKey:handler.requestID.handlerID];
            if ([handler isKindOfClass:[_DFPreheatingHandler class]]) {
                [_preheatingHandlers removeObject:handler];
            }
            if (context.handlers.count == 0) {
                [self _removeExecutionContextForECID:context.ECID];
            }
            [self _didCompleteRequestWithImage:image info:[self _infoFromResponse:context.response] handler:handler];
        });
    }];
}

- (void)_removeExecutionContextForECID:(NSString *)ECID {
    [_executionContexts removeObjectForKey:ECID];
    [self _startExecutingPreheatingRequestsIfNecessary];
}

- (void)_processImage:(UIImage *)input forHandler:(_DFRequestHandler *)handler completion:(void (^)(UIImage *image))completion {
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

- (NSDictionary *)_infoFromResponse:(DFImageResponse *)response {
    NSMutableDictionary *info = [NSMutableDictionary new];
    if (response.error != nil) {
        info[DFImageInfoErrorKey] = response.error;
    }
    [info addEntriesFromDictionary:response.userInfo];
    return [info copy];
}

- (void)_didCompleteRequestWithImage:(UIImage *)image info:(NSDictionary *)info handler:(_DFRequestHandler *)handler {
    NSMutableDictionary *mutableInfo = [NSMutableDictionary dictionaryWithDictionary:info];
    mutableInfo[DFImageInfoRequestIDKey] = handler.requestID;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (handler.completion != nil) {
            handler.completion(image, mutableInfo);
        }
    });
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
    _DFRequestExecutionContext *context = _executionContexts[requestID.ECID];
    if (context != nil) {
        [context.handlers removeObjectForKey:requestID.handlerID];
        if (context.handlers.count == 0) {
            [context.operation cancel];
            [self _removeExecutionContextForECID:requestID.ECID];
        } else {
            context.operation.queuePriority = context.queuePriority;
        }
    }
}

#pragma mark Priorities

- (void)setPriority:(DFImageRequestPriority)priority forRequestWithID:(DFImageRequestID *)requestID {
    if (requestID != nil) {
        dispatch_async(_syncQueue, ^{
            _DFRequestExecutionContext *context = _executionContexts[requestID.ECID];
            _DFRequestHandler *handler = context.handlers[requestID.handlerID];
            if (handler.request.options.priority != priority) {
                handler.request.options.priority = priority;
                NSOperation<DFImageManagerOperation> *operation = context.operation;
                operation.queuePriority = context.queuePriority;
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
        _DFPreheatingHandler *handler = [[_DFPreheatingHandler alloc] initWithRequest:request requestID:requestID completion:nil];
        [_preheatingHandlers addObject:handler];
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
        _DFPreheatingHandler *handler = [[_DFPreheatingHandler alloc] initWithRequest:request requestID:requestID completion:nil];
        [_preheatingHandlers removeObject:handler];
        [self _cancelRequestWithID:requestID];
    }
}

- (DFImageRequestID *)_preheatingIDForRequest:(DFImageRequest *)request {
    NSString *ECID = [_fetcher executionContextIDForRequest:request];
    return [DFImageRequestID requestIDWithImageManager:self ECID:ECID handlerID:_kPreheatHandlerID];
}

- (void)stopPreheatingImagesForAllRequests {
    dispatch_async(_syncQueue, ^{
        for (_DFPreheatingHandler *handler in _preheatingHandlers) {
            [self _cancelRequestWithID:handler.requestID];
        }
        [_preheatingHandlers removeAllObjects];
        /*
         [_executionContexts enumerateKeysAndObjectsUsingBlock:^(NSString *ECID, _DFRequestExecutionContext *context, BOOL *stop) {
         NSMutableArray *requestIDs = [NSMutableArray new];
         [context.handlers enumerateKeysAndObjectsUsingBlock:^(NSString *handlerID, _DFRequestHandler *handler, BOOL *stop_inner) {
         if ([handler isKindOfClass:[_DFPreheatingHandler class]]) {
         [requestIDs addObject:[DFImageRequestID requestIDWithImageManager:self ECID:ECID handlerID:handlerID]];
         }
         }];
         for (DFImageRequestID *requestID in requestIDs) {
         [self _cancelRequestWithID:requestID];
         }
         }];
         */
    });
}

- (void)_startExecutingPreheatingRequestsIfNecessary {
    if (_executionContexts.count == 0) {
        _DFPreheatingHandler *handler = [_preheatingHandlers firstObject];
        if (handler != nil) {
            NSLog(@"start executing preaheat for handler %@", handler);
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
