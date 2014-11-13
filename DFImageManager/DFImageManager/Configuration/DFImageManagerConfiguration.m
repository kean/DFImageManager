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

#import "DFImageCacheLookupOperation.h"
#import "DFImageCacheStoreOperation.h"
#import "DFImageDeserializer.h"
#import "DFImageFetchConnectionOperation.h"
#import "DFImageManager.h"
#import "DFImageManagerConfiguration.h"
#import "DFImageRequestOptions.h"
#import "DFImageResponse.h"
#import <DFCache/DFCache.h>


NSString *const DFImageManagerCacheLookupOperationType = @"DFImageManagerCacheLookupOperationType";
NSString *const DFImageManagerImageFetchOperationType = @"DFImageManagerImageFetchOperationType";
NSString *const DFImageManagerCacheStoreOperationType = @"DFImageManagerCacheStoreOperationType";


@implementation DFImageManagerConfiguration {
    NSOperationQueue *_queueForCache;
    NSOperationQueue *_queueForNetwork;
}

- (instancetype)init{
    if (self = [super init]) {
        _queueForCache = [NSOperationQueue new];
        _queueForCache.maxConcurrentOperationCount = 1;
        
        _queueForNetwork = [NSOperationQueue new];
        _queueForNetwork.maxConcurrentOperationCount = 2;
    }
    return self;
}

#pragma mark - <DFImageManagerConfiguration>

- (NSString *)imageManager:(id<DFImageManager>)manager createRequestIDForAsset:(id)asset options:(DFImageRequestOptions *)options {
    NSArray *parameters = [self parametersForOptions:options];
    NSString *assetID = [self uniqueIDForAsset:asset];
    return [NSString stringWithFormat:@"requestID?%@&asset_id=%@", [parameters componentsJoinedByString:@"&"], assetID];
}

- (NSString *)uniqueIDForAsset:(id)asset {
    if ([asset isKindOfClass:[NSString class]]) {
        return asset;
    } else {
        [NSException raise:NSInvalidArgumentException format:@"Unsupported asset %@", asset];
        return nil;
    }
}

- (NSArray *)parametersForOptions:(DFImageRequestOptions *)options {
    NSMutableArray *parameters = [NSMutableArray new];
    [parameters addObject:[NSString stringWithFormat:@"cache_storage_policy=%lu", options.cacheStoragePolicy]];
    [parameters addObject:[NSString stringWithFormat:@"network_access_allowed=%i", options.networkAccessAllowed]];
    return [parameters copy];
}

- (NSOperation<DFImageManagerOperation> *)imageManager:(id<DFImageManager>)manager createOperationForAsset:(id)asset options:(DFImageRequestOptions *)options previousOperation:(NSOperation<DFImageManagerOperation> *)previousOperation {
    NSOperation<DFImageManagerOperation> *nextOperation;
    
    NSString *previousOperationType = previousOperation ? [self operationTypeForOperation:previousOperation] : nil;
    
    if (!previousOperation) {
        if (options.cacheStoragePolicy != DFImageCacheStorageNotAllowed) {
            nextOperation = [self createCacheLookupOperationForAsset:asset options:options];
        }
        
        // cache lookup operation wasn't created
        if (!nextOperation && options.networkAccessAllowed) {
            nextOperation = [self createImageFetchOperationForAsset:asset options:options];
        }
    }
    
    else if ([previousOperationType isEqualToString:DFImageManagerCacheLookupOperationType]) {
        DFImageResponse *response = [previousOperation imageFetchResponse];
        if (!response.image && options.networkAccessAllowed) {
            nextOperation =  [self createImageFetchOperationForAsset:asset options:options];
        }
    }
    
    else if ([previousOperationType isEqualToString:DFImageManagerImageFetchOperationType]) {
        // start cache store operation
        if (options.cacheStoragePolicy != DFImageCacheStorageNotAllowed) {
            NSOperation *cacheStoreOperation = [self createCacheStoreOperationForAsset:asset options:options previousOperation:previousOperation];
            [self _enqueueOperation:cacheStoreOperation];
            return nil; // we don't wont DFImageManager to see this operation
        }
    }
    
    return nextOperation;
}

- (NSOperation<DFImageManagerOperation> *)createCacheLookupOperationForAsset:(id)asset options:(DFImageRequestOptions *)options {
    if ([asset isKindOfClass:[NSString class]]) {
        return [[DFImageCacheLookupOperation alloc] initWithAsset:asset options:options cache:[DFImageManager sharedCache]];
    } else {
        [NSException raise:NSInvalidArgumentException format:@"Unsupported asset %@", asset];
        return nil;
    }
}

- (NSOperation<DFImageManagerOperation> *)createImageFetchOperationForAsset:(id)asset options:(DFImageRequestOptions *)options {
    if ([asset isKindOfClass:[NSString class]]) {
        NSURL *URL = [NSURL URLWithString:asset];
        NSMutableURLRequest *HTTPRequest = [[NSMutableURLRequest alloc] initWithURL:URL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.f];
        DFImageFetchConnectionOperation *operation = [[DFImageFetchConnectionOperation alloc] initWithRequest:HTTPRequest];
        operation.deserializer = [DFImageDeserializer new];
        return operation;
    }
    return nil;
}

- (NSOperation *)createCacheStoreOperationForAsset:(id)asset options:(DFImageRequestOptions *)options previousOperation:(NSOperation<DFImageManagerOperation> *)previousOperation {
    DFImageResponse *response = [previousOperation imageFetchResponse];
    DFCache *cache = [DFImageManager sharedCache];
    if (cache) {
        return [[DFImageCacheStoreOperation alloc] initWithAsset:asset options:options response:response cache:cache];
    } else {
        return nil;
    }
}

- (NSString *)operationTypeForOperation:(NSOperation *)operation {
    if ([operation isKindOfClass:[DFImageCacheLookupOperation class]]) {
        return DFImageManagerCacheLookupOperationType;
    } else if ([operation isKindOfClass:[DFImageFetchConnectionOperation class]]) {
        return DFImageManagerImageFetchOperationType;
    } else  if ([operation isKindOfClass:[DFImageCacheStoreOperation class]]){
        return DFImageManagerCacheStoreOperationType;
    } else {
        return nil;
    }
}

- (void)imageManager:(id<DFImageManager>)manager enqueueOperation:(NSOperation<DFImageManagerOperation> *)operation {
    [self _enqueueOperation:operation];
}

- (void)_enqueueOperation:(NSOperation *)operation {
    [[self operationQueueForOperation:operation] addOperation:operation];
}

- (NSOperationQueue *)operationQueueForOperation:(NSOperation *)operation {
    if (!operation) {
        return nil;
    }
    NSString *operationType = [self operationTypeForOperation:operation];
    if ([operationType isEqualToString:DFImageManagerCacheLookupOperationType] || [operationType isEqualToString:DFImageManagerCacheStoreOperationType]) {
        return _queueForCache;
    } else if ([operationType isEqualToString:DFImageManagerImageFetchOperationType]) {
        return _queueForNetwork;
    }
    return nil;
}

- (BOOL)imageManager:(id<DFImageManager>)manager shouldCancelOperation:(NSOperation<DFImageManagerOperation> *)operation {
    if ([operation isKindOfClass:[DFImageFetchConnectionOperation class]]) {
        return !operation.isExecuting;
    } else {
        return YES;
    }
}

@end
