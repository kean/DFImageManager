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

#import "DFImageRequest.h"
#import "DFImageRequestOptions.h"
#import "DFPhotosKitImageFetchOperation.h"
#import "DFPhotosKitImageFetcher.h"
#import "DFPhotosKitImageRequestOptions.h"
#import "NSURL+DFPhotosKit.h"
#import <Photos/Photos.h>

static inline NSString *_PHAssetLocalIdentifier(id resource) {
    if ([resource isKindOfClass:[PHAsset class]]) {
        return ((PHAsset *)resource).localIdentifier;
    } else {
        return [((NSURL *)resource) df_assetLocalIdentifier];
    }
}

@implementation DFPhotosKitImageFetcher {
    NSOperationQueue *_queue;
}

- (instancetype)init {
    if (self = [super init]) {
        _queue = [NSOperationQueue new];
        _queue.maxConcurrentOperationCount = 2;
    }
    return self;
}

#pragma mark - <DFImageFetching>

- (BOOL)canHandleRequest:(DFImageRequest *)request {
    id asset = request.resource;
    if ([asset isKindOfClass:[PHAsset class]]) {
        return YES;
    }
    if ([asset isKindOfClass:[NSURL class]]) {
        NSURL *URL = asset;
        if ([URL.scheme isEqualToString:DFPhotosKitURLScheme]) {
            return YES;
        }
    }
    return NO;
}

- (DFImageRequest *)canonicalRequestForRequest:(DFImageRequest *)request {
    if (!request.options || ![request.options isKindOfClass:[DFPhotosKitImageRequestOptions class]]) {
        DFImageRequest *canonicalRequest = [request copy];
        canonicalRequest.options = [[DFPhotosKitImageRequestOptions alloc] initWithOptions:request.options];
        return canonicalRequest;
    }
    return request;
}

- (BOOL)isRequestFetchEquivalent:(DFImageRequest *)request1 toRequest:(DFImageRequest *)request2 {
    if (![self isRequestCacheEquivalent:request1 toRequest:request2]) {
        return NO;
    }
    return (request1.options.allowsNetworkAccess == request2.options.allowsNetworkAccess);
}

- (BOOL)isRequestCacheEquivalent:(DFImageRequest *)request1 toRequest:(DFImageRequest *)request2 {
    if (request1 == request2) {
        return YES;
    }
    if ([request1.resource isKindOfClass:[PHAsset class]] &&
        [request2.resource isKindOfClass:[PHAsset class]]) {
        // Comparing PHAsset's directly is much faster then getting their localIdentifiers.
        if (![request1.resource isEqual:request2.resource]) {
            return NO;
        }
    } else if (![_PHAssetLocalIdentifier(request1.resource) isEqualToString:_PHAssetLocalIdentifier(request2.resource)]) {
        return NO;
    }
    if (!(CGSizeEqualToSize(request1.targetSize, request2.targetSize) &&
          request1.contentMode == request2.contentMode)) {
        return NO;
    }
    DFPhotosKitImageRequestOptions *options1 = (id)request1.options;
    DFPhotosKitImageRequestOptions *options2 = (id)request2.options;
    return (options1.version == options2.version &&
            options1.deliveryMode == options2.deliveryMode &&
            options1.resizeMode == options2.resizeMode);
}

- (NSOperation *)startOperationWithRequest:(DFImageRequest *)request progressHandler:(void (^)(double))progressHandler completion:(void (^)(DFImageResponse *))completion {
    DFPhotosKitImageFetchOperation *operation =[[DFPhotosKitImageFetchOperation alloc] initWithRequest:request];
    DFPhotosKitImageFetchOperation *__weak weakOp = operation;
    [operation setCompletionBlock:^{
        completion(weakOp.response);
    }];
    [_queue addOperation:operation];
    return operation;
}

@end
