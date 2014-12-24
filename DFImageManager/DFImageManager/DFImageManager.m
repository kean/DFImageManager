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

#import "DFImageHandlerDictionary.h"
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
@property (nonatomic, readonly) DFImageRequestCompletion completion;

- (instancetype)initWithRequest:(DFImageRequest *)request completion:(DFImageRequestCompletion)completion;

@end

@implementation _DFImageFetchHandler

- (instancetype)initWithRequest:(DFImageRequest *)request completion:(DFImageRequestCompletion)completion {
    if (self = [super init]) {
        _request = request;
        _completion = [completion copy];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %p> { request = %@, completion = %@ }", [self class], self, _request, _completion];
}

@end


@implementation DFImageManager {
    DFImageHandlerDictionary *_handlers;
    NSMutableDictionary *_operations;
    
    dispatch_queue_t _syncQueue;
}

@synthesize configuration = _conf;
@synthesize imageProcessingManager = _processor;

- (instancetype)initWithConfiguration:(id<DFImageManagerConfiguration>)configuration imageProcessingManager:(id<DFImageProcessingManager>)processingManager {
    if (self = [super init]) {
        _conf = configuration;
        _processor = processingManager;
        
        _syncQueue = dispatch_queue_create([[NSString stringWithFormat:@"%@-queue-%p", [self class], self] UTF8String], DISPATCH_QUEUE_SERIAL);
        _handlers = [DFImageHandlerDictionary new];
        _operations = [NSMutableDictionary new];
    }
    return self;
}

#pragma mark - Fetching

- (DFImageRequestOptions *)requestOptionsForAsset:(id)asset {
    DFImageRequestOptions *options;
    if ([_conf respondsToSelector:@selector(imageManager:createRequestOptionsForAsset:)]) {
        options = [_conf imageManager:self createRequestOptionsForAsset:asset];
    }
    if (!options) {
        options = [DFImageRequestOptions defaultOptions];
    }
    return options;
}

- (DFImageRequestID *)requestImageForAsset:(id)asset targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options completion:(void (^)(UIImage *, NSDictionary *))completion {
    if (!asset) {
        if (completion != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, nil);
            });
        }
        return nil;
    }
    
    // Start fetching.
    if (!options) {
        options = [self requestOptionsForAsset:asset];
    }
    DFImageRequest *request = [[DFImageRequest alloc] initWithAsset:asset targetSize:targetSize contentMode:contentMode options:options];
    NSString *operationID = [_conf imageManager:self operationIDForRequest:request];
    DFImageRequestID *requestID = [[DFImageRequestID alloc] initWithOperationID:operationID];
    
    dispatch_async(_syncQueue, ^{
        [self _requestImageForRequest:request requestID:requestID completion:completion];
    });
    return requestID;
}

- (void)_requestImageForRequest:(DFImageRequest *)request requestID:(DFImageRequestID *)requestID completion:(DFImageRequestCompletion)completion {
    // Test if resized image exists.
    // TODO: Add test whether the image should be processed
    NSString *assetUID = [_conf imageManager:self uniqueIDForAsset:request.asset];
    UIImage *image = [_processor processedImageForKey:assetUID targetSize:request.targetSize contentMode:request.contentMode];
    if (image != nil) {
        if (completion != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(image, nil);
            });
        }
        return;
    }
    
    _DFImageFetchHandler *handler = [[_DFImageFetchHandler alloc] initWithRequest:request completion:completion];
    // Subscribe hanler for a given requestID.
    [_handlers addHandler:handler forOperationID:requestID.operationID handlerID:requestID.handlerID];
    
    // find existing operation
    NSOperation<DFImageManagerOperation> *operation = _operations[requestID.operationID];
    if (operation != nil) { // similar request is already being executed
        return; // only valid operations remain in the dictionary
    } else {
        [self _requestImageForRequest:request requestID:requestID previousOperation:nil];
    }
}

- (void)_requestImageForRequest:(DFImageRequest *)request requestID:(DFImageRequestID *)requestID previousOperation:(NSOperation<DFImageManagerOperation> *)previousOperation {
    NSOperation<DFImageManagerOperation> *operation = [_conf imageManager:self createOperationForRequest:request previousOperation:previousOperation];
    if (!operation) { // no more work required
        DFImageResponse *response = [previousOperation imageFetchResponse]; // get respone from previous operation (if there is one)
        UIImage *image = response.image;
        NSDictionary *info = [self _infoFromResponse:response];
        
        NSArray *handlers = [_handlers handlersForOperationID:requestID.operationID];
        
        // Process image
        NSString *assetID = [_conf imageManager:self uniqueIDForAsset:request.asset];
        
        for (_DFImageFetchHandler *handler in handlers) {
            // TODO: Add test whether the image should be processed
            // TODO: Create extra operation for processing! Don't do it on sync queue.
            UIImage *processedImage = [_processor processImageForKey:assetID image:image targetSize:handler.request.targetSize contentMode:handler.request.contentMode];
            
            if (handler.completion != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler.completion(processedImage, info);
                });
            }
        }
        
        [_operations removeObjectForKey:requestID.operationID];
        [_handlers removeAllHandlersForOperationID:requestID.operationID];
        
        if (response.error != nil) {
            [self _didEncounterError:response.error];
        }
    } else {
        DFImageManager *__weak weakSelf = self;
        NSOperation<DFImageManagerOperation> *__weak weakOp = operation;
        [operation setCompletionBlock:^{
            [weakSelf _operationDidComplete:weakOp request:request requestID:requestID];
        }];
        NSArray *handlers = [_handlers handlersForOperationID:requestID.operationID];
        operation.queuePriority = [DFImageManager _queuePriorityForHandlers:handlers];
        _operations[requestID.operationID] = operation;
        [_conf imageManager:self enqueueOperation:operation];
    }
}

- (void)_operationDidComplete:(NSOperation<DFImageManagerOperation> *)operation request:(DFImageRequest *)request requestID:(DFImageRequestID *)requestID {
    dispatch_async(_syncQueue, ^{
        if (_operations[requestID.operationID] == operation) {
            [self _requestImageForRequest:request requestID:requestID previousOperation:operation];
        }
    });
}

- (NSDictionary *)_infoFromResponse:(DFImageResponse *)response {
    NSMutableDictionary *info = [NSMutableDictionary new];
    info[DFImageInfoSourceKey] = @(response.source);
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

#pragma mark - Cancel

- (void)cancelRequestWithID:(DFImageRequestID *)requestID {
    if (requestID != nil) {
        dispatch_async(_syncQueue, ^{
            [self _cancelRequestWithID:requestID];
        });
    }
}

- (void)_cancelRequestWithID:(DFImageRequestID *)requestID {
    [_handlers removeHandlerForOperationID:requestID.operationID handlerID:requestID.handlerID];
    NSOperation<DFImageManagerOperation> *operation = _operations[requestID.operationID];
    if (!operation) {
        return;
    }
    NSArray *remainingHandlers = [_handlers handlersForOperationID:requestID.operationID];
    BOOL cancel = remainingHandlers.count == 0;
    if (cancel && [_conf respondsToSelector:@selector(imageManager:shouldCancelOperation:)]) {
        cancel = [_conf imageManager:self shouldCancelOperation:operation];
    }
    if (cancel) {
        [operation cancel];
        [_operations removeObjectForKey:requestID.operationID];
    } else {
        operation.queuePriority = [DFImageManager _queuePriorityForHandlers:remainingHandlers];
    }
}

#pragma mark - Priorities

+ (NSOperationQueuePriority)_queuePriorityForHandlers:(NSArray *)handlers {
    DFImageRequestPriority maxPriority = DFImageRequestPriorityVeryLow;
    for (_DFImageFetchHandler *handler in handlers) {
        maxPriority = MAX(handler.request.options.priority, maxPriority);
    }
    return maxPriority;
}

- (void)setPriority:(DFImageRequestPriority)priority forRequestWithID:(DFImageRequestID *)requestID {
    if (requestID != nil) {
        dispatch_async(_syncQueue, ^{
            _DFImageFetchHandler *handler = [_handlers handlerForOperationID:requestID.operationID handlerID:requestID.handlerID];
            if (handler.request.options.priority != priority) {
                handler.request.options.priority = priority;
                NSOperation<DFImageManagerOperation> *operation = _operations[requestID.operationID];
                NSArray *handlers = [_handlers handlersForOperationID:requestID.operationID];
                operation.queuePriority = [DFImageManager _queuePriorityForHandlers:handlers];;
            }
        });
    }
}

#pragma mark - Preheating

- (void)startPreheatingImageForAssets:(NSArray *)assets targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options {
    if (assets.count) {
        dispatch_async(_syncQueue, ^{
            [self _startPreheatingImageForAssets:assets targetSize:targetSize contentMode:contentMode options:options];
        });
    }
}

- (void)stopPreheatingImagesForAssets:(NSArray *)assets targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options {
    if (assets.count) {
        dispatch_async(_syncQueue, ^{
            [self _stopPreheatingImagesForAssets:assets targetSize:targetSize contentMode:contentMode options:options];
        });
    }
}

- (void)_startPreheatingImageForAssets:(NSArray *)assets targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options {
    for (id asset in assets) {
        options = [self _preheatingOptionsForAsset:asset options:options];
        DFImageRequest *request = [[DFImageRequest alloc] initWithAsset:asset targetSize:targetSize contentMode:contentMode options:options];
        DFImageRequestID *requestID = [self _preheatingIDForRequest:request];
        _DFImageFetchHandler *handler = [_handlers handlerForOperationID:requestID.operationID handlerID:requestID.handlerID];
        if (!handler) {
            [self _requestImageForRequest:request requestID:requestID completion:nil];
        }
    }
}

- (void)_stopPreheatingImagesForAssets:(NSArray *)assets targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options {
    for (id asset in assets) {
        options = [self _preheatingOptionsForAsset:asset options:options];
        DFImageRequest *request = [[DFImageRequest alloc] initWithAsset:asset targetSize:targetSize contentMode:contentMode options:options];
        DFImageRequestID *requestID = [self _preheatingIDForRequest:request];
        [self _cancelRequestWithID:requestID];
    }
}

- (DFImageRequestOptions *)_preheatingOptionsForAsset:(id)asset options:(DFImageRequestOptions *)options {
    if (!options) {
        options = [self requestOptionsForAsset:asset];
        options.priority = DFImageRequestPriorityLow;
    }
    return options;
}

- (DFImageRequestID *)_preheatingIDForRequest:(DFImageRequest *)request {
    NSString *operationID = [_conf imageManager:self operationIDForRequest:request];
    return [[DFImageRequestID alloc] initWithOperationID:operationID handlerID:@"preheat"];
}

- (void)stopPreheatingImageForAllAssets {
    dispatch_async(_syncQueue, ^{
        NSDictionary *handlers = [_handlers allHandlers];
        [handlers enumerateKeysAndObjectsUsingBlock:^(NSString *requestID, NSDictionary *handlersForOperation, BOOL *stop) {
            NSMutableArray *requestIDs = [NSMutableArray new];
            [handlersForOperation enumerateKeysAndObjectsUsingBlock:^(NSString *handlerID, _DFImageFetchHandler *handler, BOOL *stop) {
                if ([handlerID isEqualToString:@"preheat"]) {
                    [requestIDs addObject:[[DFImageRequestID alloc] initWithOperationID:requestID handlerID:handlerID]];
                }
            }];
            for (DFImageRequestID *requestID in requestIDs) {
                [self _cancelRequestWithID:requestID];
            }
        }];
    });
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
