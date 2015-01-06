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
#import "DFImageRequest.h"
#import "DFImageRequestOptions.h"
#import "DFImageResponse.h"
#import "DFNetworkImageManagerConfiguration.h"
#import "DFURLConnectionOperation.h"
#import "DFURLResponseDeserializing.h"
#import <DFCache/DFCache.h>


@implementation DFNetworkImageManagerConfiguration {
    NSOperationQueue *_queueForCache;
    NSOperationQueue *_queueForNetwork;
}

- (instancetype)initWithCache:(DFCache *)cache {
    if (self = [super init]) {
        _cache = cache;
        
        _queueForCache = [NSOperationQueue new];
        _queueForCache.maxConcurrentOperationCount = 1;
        
        _queueForNetwork = [NSOperationQueue new];
        _queueForNetwork.maxConcurrentOperationCount = 2;
    }
    return self;
}

#pragma mark - <DFImageManagerConfiguration>

- (BOOL)imageManager:(id<DFImageManager>)manager canHandleRequest:(DFImageRequest *)request {
    return [request.asset isKindOfClass:[NSString class]];
}

- (NSString *)imageManager:(id<DFImageManager>)manager uniqueIDForAsset:(id)asset {
    return (NSString *)asset;
}

- (NSArray *)keyPathForRequestParametersAffectingOperationID:(DFImageRequest *)request {
    static NSArray *_keyPaths;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _keyPaths = @[ @"options.cacheStoragePolicy",
                       @"options.networkAccessAllowed" ];
        
    });
    return _keyPaths;
}

#pragma mark - Subclassing Hooks

- (NSOperation<DFImageManagerOperation> *)createCacheLookupOperationForRequest:(DFImageRequest *)request {
    if (self.cache != nil) {
        return [[DFImageCacheLookupOperation alloc] initWithAsset:request.asset options:request.options cache:self.cache];
    } else {
        return nil;
    }
}

- (NSOperation<DFImageManagerOperation> *)createImageFetchOperationForRequest:(DFImageRequest *)request {
    if (request.options.networkAccessAllowed) {
        NSURL *URL = [NSURL URLWithString:request.asset];
        NSMutableURLRequest *HTTPRequest = [[NSMutableURLRequest alloc] initWithURL:URL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.f];
        DFImageFetchConnectionOperation *operation = [[DFImageFetchConnectionOperation alloc] initWithRequest:HTTPRequest];
        operation.deserializer = [DFImageDeserializer new];
        return operation;
    } else {
        return nil;
    }
}

- (NSOperation *)createCacheStoreOperationForRequest:(DFImageRequest *)request previousOperation:(NSOperation<DFImageManagerOperation> *)previousOperation {
    DFImageResponse *response = [previousOperation imageResponse];
    if (self.cache != nil) {
        return [[DFImageCacheStoreOperation alloc] initWithAsset:request.asset options:request.options response:response cache:self.cache];
    } else {
        return nil;
    }
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

@end
