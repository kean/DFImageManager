// The MIT License (MIT)
//
// Copyright (c) 2014 Alexander Grebenyuk (github.com/kean).
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

@interface _DFImageFetchHandler : NSObject

@property (nonatomic, readonly) DFImageRequest *request;
@property (nonatomic, readonly) DFImageRequestID *requestID;
@property (nonatomic, readonly) DFImageRequestCompletion completion;

- (instancetype)initWithRequest:(DFImageRequest *)request requestID:(DFImageRequestID *)requestID completion:(DFImageRequestCompletion)completion NS_DESIGNATED_INITIALIZER;

@end

@implementation _DFImageFetchHandler

- (instancetype)initWithRequest:(DFImageRequest *)request requestID:(DFImageRequestID *)requestID completion:(DFImageRequestCompletion)completion {
    if (self = [super init]) {
        _request = request;
        _requestID = requestID;
        _completion = [completion copy];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %p> { request = %@, requestID = %@, completion = %@ }", [self class], self, self.request, self.requestID, self.completion];
}

@end


@interface _DFRequestExecutionContext : NSObject

@property (nonatomic, readonly) DFImageRequest *request;
@property (nonatomic) NSOperation<DFImageManagerOperation> *currentOperation;
@property (nonatomic, readonly) NSMutableDictionary *handlers;

- (instancetype)initWithRequest:(DFImageRequest *)request;

/*! Returns maximum queue priority from handlers.
 */
@property (nonatomic, readonly) NSOperationQueuePriority queuePriority;

@end

@implementation _DFRequestExecutionContext

- (instancetype)initWithRequest:(DFImageRequest *)request {
    if (self = [super init]) {
        _request = request;
        _handlers = [NSMutableDictionary new];
    }
    return self;
}

- (NSOperationQueuePriority)queuePriority {
    DFImageRequestPriority __block maxPriority = DFImageRequestPriorityVeryLow;
    [_handlers enumerateKeysAndObjectsUsingBlock:^(id key, _DFImageFetchHandler *handler, BOOL *stop) {
        maxPriority = MAX(handler.request.options.priority, maxPriority);
    }];
    return (NSOperationQueuePriority)maxPriority;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %p> { request = %@, currentOperation = %@, handlers = %@ }", [self class], self, self.request, self.currentOperation, self.handlers];
}

@end


/*! Implementation details.
 - Each DFImageRequest+completion pair has it's own assigned DFImageRequestID
 - Multiple requests+completion might be handled by the same _DFRequestExecutionContext 
 */
@implementation DFImageManager {
    NSMutableDictionary /* NSString *operationID : _DFRequestExecutionContext */ *_executionContexts;
    
    dispatch_queue_t _syncQueue;
}

@synthesize configuration = _conf;
@synthesize imageProcessor = _processor;

- (instancetype)initWithConfiguration:(id<DFImageManagerConfiguration>)configuration imageProcessor:(id<DFImageProcessing>)imageProcessor cache:(id<DFImageCaching>)cache {
    if (self = [super init]) {
        _conf = configuration;
        _processor = imageProcessor;
        _cache = cache;
        
        _syncQueue = dispatch_queue_create([[NSString stringWithFormat:@"%@-queue-%p", [self class], self] UTF8String], DISPATCH_QUEUE_SERIAL);
        _executionContexts = [NSMutableDictionary new];
    }
    return self;
}

#pragma mark - <DFCoreImageManager>

- (BOOL)canHandleRequest:(DFImageRequest *)request {
    return [_conf imageManager:self canHandleRequest:request];
}

#pragma mark Fetching

- (DFImageRequestID *)requestImageForRequest:(DFImageRequest *)request completion:(DFImageRequestCompletion)completion {
    request = [request copy];
    DFImageRequestID *requestID = [[DFImageRequestID alloc] initWithImageManager:self]; // Represents requestID future.
    dispatch_async(_syncQueue, ^{
        NSString *operationID = [_conf imageManager:self operationIDForRequest:request];
        [requestID setOperationID:operationID handlerID:[[NSUUID UUID] UUIDString]];
        [self _requestImageForRequest:request requestID:requestID completion:completion];
    });
    return requestID;
}

- (void)_requestImageForRequest:(DFImageRequest *)request requestID:(DFImageRequestID *)requestID completion:(DFImageRequestCompletion)completion {
    // TODO: Move this code + subscribe for image processing operation.
    
    if (_cache != nil) {
        NSString *asssetID = [_conf imageManager:self uniqueIDForAsset:request.asset];
        UIImage *image = [_cache cachedImageForAssetID:asssetID request:request];
        if (image != nil) {
            [self _completeRequestWithImage:image info:@{ DFImageInfoResultIsFromMemoryCacheKey : @YES } requestID:requestID completion:completion];
            return;
        }
    }

    _DFImageFetchHandler *handler = [[_DFImageFetchHandler alloc] initWithRequest:request requestID:requestID completion:completion];
    
    _DFRequestExecutionContext *context = _executionContexts[requestID.operationID];
    if (!context) {
        context = [[_DFRequestExecutionContext alloc] initWithRequest:request];
        context.handlers[requestID.handlerID] = handler;
        _executionContexts[requestID.operationID] = context;
        [self _requestImageForRequest:request operationID:requestID.operationID previousOperation:nil];
    } else {
        context.handlers[requestID.handlerID] = handler;
    }
}

- (void)_requestImageForRequest:(DFImageRequest *)request operationID:(NSString *)operationID previousOperation:(NSOperation<DFImageManagerOperation> *)previousOperation {
    NSOperation<DFImageManagerOperation> *operation = [_conf imageManager:self createOperationForRequest:request previousOperation:previousOperation];
    if (!operation) { // No more work required.
        DFImageResponse *response = [previousOperation imageFetchResponse];
        [self _didCompleteAllOperationsForID:operationID response:response];
    } else {
        DFImageManager *__weak weakSelf = self;
        NSOperation<DFImageManagerOperation> *__weak weakOp = operation;
        [operation setCompletionBlock:^{
            [weakSelf _didCompleteOperation:weakOp request:request operationID:operationID];
        }];
        
        _DFRequestExecutionContext *context = _executionContexts[operationID];
        operation.queuePriority = context.queuePriority;
        context.currentOperation = operation;
        
        [_conf imageManager:self enqueueOperation:operation];
    }
}

- (void)_didCompleteOperation:(NSOperation<DFImageManagerOperation> *)operation request:(DFImageRequest *)request operationID:(NSString *)operationID {
    dispatch_async(_syncQueue, ^{
        _DFRequestExecutionContext *context = _executionContexts[operationID];
        if (context.currentOperation == operation) {
            context.currentOperation = nil; // TODO: Do we really need to do this?
            [self _requestImageForRequest:request operationID:operationID previousOperation:operation];
        }
    });
}

- (void)_didCompleteAllOperationsForID:(NSString *)operationID response:(DFImageResponse *)response {
    UIImage *image = response.image;
    NSDictionary *info = [self _infoFromResponse:response];
    
    _DFRequestExecutionContext *context = _executionContexts[operationID];
    NSArray *handlers = [context.handlers allValues];
    [_executionContexts removeObjectForKey:operationID];
    
    for (_DFImageFetchHandler *handler in handlers) {
        DFImageRequest *request = handler.request;
        DFImageRequestID *requestID = handler.requestID;
        DFImageRequestCompletion completion = handler.completion;
                
        NSString *assetID = [_conf imageManager:self uniqueIDForAsset:request.asset];
        if (_processor != nil && image != nil) {
            [_processor processImage:image forRequest:request completion:^(UIImage *image) {
                [_cache storeImage:image forAssetID:assetID request:request];
                [self _completeRequestWithImage:image info:info requestID:requestID completion:completion];
            }];
        } else {
            [_cache storeImage:image forAssetID:assetID request:request];
            [self _completeRequestWithImage:image info:info requestID:requestID completion:completion];
        }
    }
    
    if (response.error != nil) {
        [self _didEncounterError:response.error];
    }
}

- (void)_completeRequestWithImage:(UIImage *)image info:(NSDictionary *)info requestID:(DFImageRequestID *)requestID completion:(DFImageRequestCompletion)completion {
    if (completion != nil) {
        NSMutableDictionary *mutableInfo = [NSMutableDictionary dictionaryWithDictionary:info];
        mutableInfo[DFImageInfoRequestIDKey] = requestID;
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(image, mutableInfo);
        });
    }
}

- (NSDictionary *)_infoFromResponse:(DFImageResponse *)response {
    NSMutableDictionary *info = [NSMutableDictionary new];
    if (response.error != nil) {
        info[DFImageInfoErrorKey] = response.error;
    }
    if (response.data != nil) {
        info[DFImageInfoDataKey] = response.data;
    }
    [info addEntriesFromDictionary:response.userInfo];
    return [info copy];
}

- (void)_didEncounterError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_conf respondsToSelector:@selector(imageManager:didEncounterError:)]) {
            [_conf imageManager:self didEncounterError:error];
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
    _DFRequestExecutionContext *context = _executionContexts[requestID.operationID];
    [context.handlers removeObjectForKey:requestID.handlerID];
    NSOperation<DFImageManagerOperation> *operation = context.currentOperation;
    if (!operation) {
        return;
    }
    if (context.handlers.count == 0) {
        [operation cancel];
        [_executionContexts removeObjectForKey:requestID.operationID];
    } else {
        operation.queuePriority = context.queuePriority;
    }
}

#pragma mark Priorities

+ (NSOperationQueuePriority)_queuePriorityForHandlers:(NSArray *)handlers {
    DFImageRequestPriority maxPriority = DFImageRequestPriorityVeryLow;
    for (_DFImageFetchHandler *handler in handlers) {
        maxPriority = MAX(handler.request.options.priority, maxPriority);
    }
    return (NSOperationQueuePriority)maxPriority;
}

- (void)setPriority:(DFImageRequestPriority)priority forRequestWithID:(DFImageRequestID *)requestID {
    if (requestID != nil) {
        dispatch_async(_syncQueue, ^{
            _DFRequestExecutionContext *context = _executionContexts[requestID.operationID];
            _DFImageFetchHandler *handler = context.handlers[requestID.handlerID];
            if (handler.request.options.priority != priority) {
                handler.request.options.priority = priority;
                NSOperation<DFImageManagerOperation> *operation = context.currentOperation;
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
        request.options.priority = DFImageRequestPriorityLow;
        DFImageRequestID *requestID = [self _preheatingIDForRequest:request];
        _DFRequestExecutionContext *context = _executionContexts[requestID.operationID];
        _DFImageFetchHandler *handler = context.handlers[requestID.handlerID];
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
        request.options.priority = DFImageRequestPriorityLow;
        DFImageRequestID *requestID = [self _preheatingIDForRequest:request];
        [self _cancelRequestWithID:requestID];
    }
}

- (DFImageRequestID *)_preheatingIDForRequest:(DFImageRequest *)request {
    NSString *operationID = [_conf imageManager:self operationIDForRequest:request];
    return [DFImageRequestID requestIDWithImageManager:self operationID:operationID handlerID:@"preheat"];
}

- (void)stopPreheatingImageForAllAssets {
    dispatch_async(_syncQueue, ^{
        [_executionContexts enumerateKeysAndObjectsUsingBlock:^(NSString *operationID, _DFRequestExecutionContext *context, BOOL *stop) {
            NSMutableArray *operationIDs = [NSMutableArray new];
            [context.handlers enumerateKeysAndObjectsUsingBlock:^(NSString *handlerID, _DFImageFetchHandler *handler, BOOL *stop) {
                if ([handlerID isEqualToString:@"preheat"]) {
                    [operationIDs addObject:[DFImageRequestID requestIDWithImageManager:self operationID:operationID handlerID:handlerID]];
                }
            }];
            for (DFImageRequestID *requestID in operationIDs) {
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
