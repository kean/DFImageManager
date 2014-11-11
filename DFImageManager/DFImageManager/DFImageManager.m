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
#import "DFImageHandlerDictionary.h"
#import "DFImageRequestID+Protected.h"
#import "DFImageRequestID.h"
#import "DFImageRequestOptions.h"
#import "DFImageResponse.h"


@interface _DFImageFetchHandler : NSObject

@property (nonatomic) id asset;
@property (nonatomic, copy) DFImageRequestOptions *options;
@property (nonatomic, copy) DFImageRequestCompletion completion;
@property (nonatomic) BOOL isPrefetch;

- (instancetype)initWithAsset:(id)asset options:(DFImageRequestOptions *)options completion:(DFImageRequestCompletion)completion;

@end

@implementation _DFImageFetchHandler

- (instancetype)initWithAsset:(id)asset options:(DFImageRequestOptions *)options completion:(DFImageRequestCompletion)completion {
   if (self = [super init]) {
      _asset = asset;
      _options = options;
      _completion = completion;
   }
   return self;
}

- (NSString *)description {
   return [NSString stringWithFormat:@"<%@ %p> { asset = %@, options = %@, completion = %@ }", [self class], self, _asset, _options, _completion];
}

@end


@implementation DFImageManager {
   DFImageHandlerDictionary *_handlers;
   NSMutableDictionary *_operations;
   
   dispatch_queue_t _syncQueue;
}

@synthesize configuration = _conf;

- (instancetype)initWithConfiguration:(id<DFImageManagerConfiguration>)configuration {
   if (self = [super init]) {
      _conf = configuration;
      
      _syncQueue = dispatch_queue_create([[NSString stringWithFormat:@"%@-queue-%p", [self class], self] UTF8String], DISPATCH_QUEUE_SERIAL);
      _handlers = [DFImageHandlerDictionary new];
      _operations = [NSMutableDictionary new];
   }
   return self;
}

#pragma mark - Fetching

- (DFImageRequestOptions *)requestOptionsForAsset:(id)asset {
   DFImageRequestOptions *options = [_conf imageManager:self createRequestOptionsForAsset:asset];
   NSAssert(options, @"Options must not be nil");
   return options;
}

- (DFImageRequestID *)requestImageForAsset:(id)asset options:(DFImageRequestOptions *)options completion:(DFImageRequestCompletion)completion {
   NSParameterAssert(asset);
   if (!asset) {
      dispatch_async(dispatch_get_main_queue(), ^{
         if (completion) {
            completion(nil, nil);
         }
      });
      return nil;
   }
   if (!options) {
      options = [_conf imageManager:self createRequestOptionsForAsset:asset];
   }
   NSString *stringRequestID = [_conf imageManager:self createRequestIDForAsset:asset options:options];
   DFImageRequestID *requestID = [[DFImageRequestID alloc] initWithRequestID:stringRequestID];
   
   dispatch_async(_syncQueue, ^{
      _DFImageFetchHandler *handler = [[_DFImageFetchHandler alloc] initWithAsset:asset options:options completion:completion];
      // Subscribe hanler for a given requestID.
      [_handlers addHandler:handler forRequestID:requestID.requestID handler:requestID.handlerID];
      
      // find existing operation
      NSOperation<DFImageManagerOperation> *operation = _operations[requestID.requestID];
      if (operation) { // similar request is already being executed
         return; // only valid operations remain in the dictionary
      } else {
         [self _requestImageForAsset:asset options:options requestID:requestID previousOperation:nil];
      }
   });
   return requestID;
}

- (void)_requestImageForAsset:(id)asset options:(DFImageRequestOptions *)options requestID:(DFImageRequestID *)requestID previousOperation:(NSOperation<DFImageManagerOperation> *)previousOperation {
   NSOperation<DFImageManagerOperation> *operation = [_conf imageManager:self createOperationForAsset:asset options:options previousOperation:previousOperation];
   if (!operation) { // no more work required
      DFImageResponse *response = [previousOperation imageFetchResponse]; // get respone from previous operation (if there is one)
      UIImage *image = response.image;
      NSDictionary *info = [self _infoFromResponse:response];
      
      NSArray *handlers = [_handlers handlersForRequestID:requestID.requestID];
      dispatch_async(dispatch_get_main_queue(), ^{
         for (_DFImageFetchHandler *handler in handlers) {
            if (handler.completion) {
               handler.completion(image, info);
            }
         }
      });
      
      [_operations removeObjectForKey:requestID.requestID];
      [_handlers removeAllHandlersForRequestID:requestID.requestID];
      
      if (response.error) {
         [self _didEncounterError:response.error];
      }
   } else {
      DFImageManager *__weak weakSelf = self;
      NSOperation<DFImageManagerOperation> *__weak weakOp = operation;
      [operation setCompletionBlock:^{
         [weakSelf _operationDidComplete:weakOp asset:asset options:options requestID:requestID];
      }];
      NSArray *handlers = [_handlers handlersForRequestID:requestID.requestID];
      operation.queuePriority = [DFImageManager _queuePriorityForHandlers:handlers];
      _operations[requestID.requestID] = operation;
      [_conf imageManager:self enqueueOperation:operation];
   }
}

- (void)_operationDidComplete:(NSOperation<DFImageManagerOperation> *)operation asset:(id)asset options:(DFImageRequestOptions *)options requestID:(DFImageRequestID *)requestID {
   dispatch_async(_syncQueue, ^{
      if (_operations[requestID.requestID] == operation) {
         [self _requestImageForAsset:asset options:options requestID:requestID previousOperation:operation];
      }
   });
}

- (NSDictionary *)_infoFromResponse:(DFImageResponse *)response {
   NSMutableDictionary *info = [NSMutableDictionary new];
   info[DFImageInfoSourceKey] = @(response.source);
   if (response.error) {
      info[DFImageInfoErrorKey] = response.error;
   }
   if (response.data) {
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
   if (requestID) {
      dispatch_async(_syncQueue, ^{
         [self _cancelRequestWithID:requestID];
      });
   }
}

- (void)_cancelRequestWithID:(DFImageRequestID *)requestID {
   [_handlers removeHandlerForRequestID:requestID.requestID handlerID:requestID.handlerID];
   NSOperation<DFImageManagerOperation> *operation = _operations[requestID.requestID];
   if (!operation) {
      return;
   }
   NSArray *remainingHandlers = [_handlers handlersForRequestID:requestID.requestID];
   BOOL cancel = remainingHandlers.count == 0 && [_conf imageManager:self shouldCancelOperation:operation];
   if (cancel) {
      [operation cancel];
      [_operations removeObjectForKey:requestID.requestID];
   } else {
      operation.queuePriority = [DFImageManager _queuePriorityForHandlers:remainingHandlers];
   }
}

#pragma mark - Priorities

+ (NSOperationQueuePriority)_queuePriorityForHandlers:(NSArray *)handlers {
   DFImageRequestPriority maxPriority = DFImageRequestPriorityVeryLow;
   for (_DFImageFetchHandler *handler in handlers) {
      maxPriority = MAX(handler.options.priority, maxPriority);
   }
   return maxPriority;
}

- (void)setPriority:(DFImageRequestPriority)priority forRequestWithID:(DFImageRequestID *)requestID {
   if (requestID) {
      dispatch_async(_syncQueue, ^{
         _DFImageFetchHandler *handler = [_handlers handlerForRequestID:requestID.requestID handlerID:requestID.handlerID];
         if (handler.options.priority != priority) {
            handler.options.priority = priority;
            NSOperation<DFImageManagerOperation> *operation = _operations[requestID.requestID];
            NSArray *handlers = [_handlers handlersForRequestID:requestID.requestID];
            operation.queuePriority = [DFImageManager _queuePriorityForHandlers:handlers];;
         }
      });
   }
}

#pragma mark - Prefetching

- (DFImageRequestID *)prefetchImageForAsset:(id)asset options:(DFImageRequestOptions *)options {
   if (!asset) {
      return nil;
   }
   if (!options) {
      options = [_conf imageManager:self createRequestOptionsForAsset:asset];
      options.priority = DFImageRequestPriorityLow;
   }
   options.prefetch = YES;
   return [self requestImageForAsset:asset options:options completion:nil];
}

- (void)stopPrefetchingAllImages {
   dispatch_async(_syncQueue, ^{
      NSDictionary *handlers = [_handlers allHandlers];
      [handlers enumerateKeysAndObjectsUsingBlock:^(NSString *requestID, NSDictionary *handlersForOperation, BOOL *stop) {
         NSMutableArray *requestIDs = [NSMutableArray new];
         [handlersForOperation enumerateKeysAndObjectsUsingBlock:^(NSString *handlerID, _DFImageFetchHandler *handler, BOOL *stop) {
            if (handler.options.prefetch) {
               [requestIDs addObject:[[DFImageRequestID alloc] initWithRequestID:requestID handlerID:handlerID]];
            }
         }];
         for (DFImageRequestID *requestID in requestIDs) {
            [self _cancelRequestWithID:requestID];
         }
      }];
   });
}

- (NSArray *)_prefetchHandlersFromHandlers:(NSArray *)handlers {
   NSMutableArray *prefetchHandlers = [NSMutableArray new];
   for (_DFImageFetchHandler *handler in handlers) {
      if (handler.options.prefetch) {
         [prefetchHandlers addObject:handler];
      }
   }
   return prefetchHandlers;
}

@end
