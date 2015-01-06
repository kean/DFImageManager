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
#import "DFImageManagerConfiguration.h"
#import "DFImageRequest.h"
#import "DFImageRequestOptions.h"
#import "DFImageResponse.h"


NSString *const DFImageManagerCacheLookupOperationType = @"DFImageManagerCacheLookupOperationType";
NSString *const DFImageManagerImageFetchOperationType = @"DFImageManagerImageFetchOperationType";
NSString *const DFImageManagerCacheStoreOperationType = @"DFImageManagerCacheStoreOperationType";


@implementation DFImageManagerConfiguration

#pragma mark - <DFImageManagerConfiguration>

- (BOOL)imageManager:(id<DFImageManager>)manager canHandleRequest:(DFImageRequest *)request {
    return NO;
}

- (NSString *)imageManager:(id<DFImageManager>)manager uniqueIDForAsset:(id)asset {
    [NSException raise:NSInvalidArgumentException format:@"Abstract method called %@", NSStringFromSelector(_cmd)];
    return nil;
}

- (NSString *)imageManager:(id<DFImageManager>)manager executionContextIDForRequest:(DFImageRequest *)request {
    NSString *assetID = [self imageManager:manager uniqueIDForAsset:request.asset];
    
    NSMutableString *operationID = [[NSMutableString alloc] initWithString:@"requestID?"];
    NSArray *keyPaths = [self keyPathForRequestParametersAffectingOperationID:request];
    for (NSString *keyPath in keyPaths) {
        [operationID appendFormat:@"%@=%@&", keyPath, [request valueForKeyPath:keyPath]];
    }
    [operationID appendFormat:@"assetID=%@", assetID];
    return operationID;
}

- (NSArray *)keyPathForRequestParametersAffectingOperationID:(DFImageRequest *)request {
    return @[];
}

- (NSOperation<DFImageManagerOperation> *)imageManager:(id<DFImageManager>)manager createOperationForRequest:(DFImageRequest *)request previousOperation:(NSOperation<DFImageManagerOperation> *)previousOperation {
    NSOperation<DFImageManagerOperation> *nextOperation;
    
    NSString *previousOperationType = previousOperation ? [self operationTypeForOperation:previousOperation] : nil;
    
    DFImageRequestOptions *options = request.options;
    
    if (!previousOperation) {
        if (options.cacheStoragePolicy != DFImageCacheStorageNotAllowed) {
            nextOperation = [self createCacheLookupOperationForRequest:request];
        }
        
        // cache lookup operation wasn't created
        if (!nextOperation && options.networkAccessAllowed) {
            nextOperation = [self createImageFetchOperationForRequest:request];
        }
    }
    
    else if ([previousOperationType isEqualToString:DFImageManagerCacheLookupOperationType]) {
        DFImageResponse *response = [previousOperation imageFetchResponse];
        if (!response.image) {
            nextOperation =  [self createImageFetchOperationForRequest:request];
        }
    }
    
    else if ([previousOperationType isEqualToString:DFImageManagerImageFetchOperationType]) {
        // start cache store operation
        if (options.cacheStoragePolicy != DFImageCacheStorageNotAllowed) {
            NSOperation *cacheStoreOperation = [self createCacheStoreOperationForRequest:request previousOperation:previousOperation];
            [self _enqueueOperation:cacheStoreOperation];
            return nil; // we don't wont DFImageManager to see this operation
        }
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

- (NSString *)operationTypeForOperation:(NSOperation *)operation {
    return nil;
}

- (void)imageManager:(id<DFImageManager>)manager enqueueOperation:(NSOperation<DFImageManagerOperation> *)operation {
    [self _enqueueOperation:operation];
}

- (void)_enqueueOperation:(NSOperation *)operation {
    [[self operationQueueForOperation:operation] addOperation:operation];
}

- (NSOperationQueue *)operationQueueForOperation:(NSOperation *)operation {
    return nil;
}

@end
