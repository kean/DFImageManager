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
#import "DFCachingImageFetcher.h"
#import "DFImageRequest.h"
#import "DFImageRequestOptions.h"
#import "DFImageResponse.h"
#import <objc/runtime.h>


static NSString *const DFImageCacheLookupOperationType = @"DFImageCacheLookupOperationType";
static NSString *const DFImageFetchOperationType = @"DFImageFetchOperationType";


static char _operationTypeToken;

@implementation DFCachingImageFetcher

#pragma mark - <DFImageFetcher>

- (BOOL)canHandleRequest:(DFImageRequest *)request {
    return NO;
}

- (NSString *)uniqueIDForAsset:(id)asset {
    [NSException raise:NSInvalidArgumentException format:@"Abstract method called %@", NSStringFromSelector(_cmd)];
    return nil;
}

- (NSString *)executionContextIDForRequest:(DFImageRequest *)request {
    NSString *assetID = [self uniqueIDForAsset:request.asset];
    
    NSMutableString *ECID = [[NSMutableString alloc] initWithString:@"requestID?"];
    NSArray *keyPaths = [self keyPathsAffectingExecutionContextIDForRequest:request];
    for (NSString *keyPath in keyPaths) {
        [ECID appendFormat:@"%@=%@&", keyPath, [request valueForKeyPath:keyPath]];
    }
    [ECID appendFormat:@"assetID=%@", assetID];
    return ECID;
}

- (NSArray *)keyPathsAffectingExecutionContextIDForRequest:(DFImageRequest *)request {
    return @[];
}

- (NSOperation<DFImageManagerOperation> *)createOperationForRequest:(DFImageRequest *)request previousOperation:(NSOperation<DFImageManagerOperation> *)previousOperation {
    NSOperation<DFImageManagerOperation> *nextOperation;
    
    NSString *previousOperationType = objc_getAssociatedObject(previousOperation, &_operationTypeToken);
    
    DFImageRequestOptions *options = request.options;
    
    NSString *nextOperationType;
    
    if (!previousOperation) {
        if (options.cacheStoragePolicy != DFImageCacheStorageNotAllowed) {
            nextOperation = [self createCacheLookupOperationForRequest:request];
            nextOperationType = DFImageCacheLookupOperationType;
        }
        
        // cache lookup operation wasn't created
        if (!nextOperation && options.networkAccessAllowed) {
            nextOperation = [self createImageFetchOperationForRequest:request];
            nextOperationType = DFImageFetchOperationType;
        }
    }
    
    else if ([previousOperationType isEqualToString:DFImageCacheLookupOperationType]) {
        DFImageResponse *response = [previousOperation imageResponse];
        if (!response.image) {
            nextOperation =  [self createImageFetchOperationForRequest:request];
            nextOperationType = DFImageFetchOperationType;
        }
    }
    
    else if ([previousOperationType isEqualToString:DFImageFetchOperationType]) {
        // start cache store operation
        if (options.cacheStoragePolicy != DFImageCacheStorageNotAllowed) {
            NSOperation *cacheStoreOperation = [self createCacheStoreOperationForRequest:request previousOperation:previousOperation];
            [self _enqueueOperation:cacheStoreOperation];
            return nil; // we don't wont DFImageManager to see this operation
        }
    }
    
    if (nextOperationType != nil && nextOperation != nil) {
        objc_setAssociatedObject(nextOperation, &_operationTypeToken, nextOperationType, OBJC_ASSOCIATION_COPY);
    }
    return nextOperation;
}

- (NSOperation<DFImageManagerOperation> *)createCacheLookupOperationForRequest:(DFImageRequest *)request {
    return nil;
}

- (NSOperation<DFImageManagerOperation> *)createImageFetchOperationForRequest:(DFImageRequest *)request {
    return nil;
}

- (NSOperation *)createCacheStoreOperationForRequest:(DFImageRequest *)request previousOperation:(NSOperation<DFImageManagerOperation> *)previousOperation {
    return nil;
}

- (void)enqueueOperation:(NSOperation<DFImageManagerOperation> *)operation {
    [self _enqueueOperation:operation];
}

- (void)_enqueueOperation:(NSOperation *)operation {
    [[self operationQueueForOperation:operation] addOperation:operation];
}

- (NSOperationQueue *)operationQueueForOperation:(NSOperation *)operation {
    return nil;
}

@end
