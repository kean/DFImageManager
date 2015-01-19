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
#import "NSURL+DFImageAsset.h"
#import "NSURL+DFPhotosKit.h"
#import <Photos/Photos.h>


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

#pragma mark - <DFImageFetcher>

- (BOOL)canHandleRequest:(DFImageRequest *)request {
    id asset = request.asset;
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

- (BOOL)isRequestEquivalent:(DFImageRequest *)request1 toRequest:(DFImageRequest *)request2 {
    if (request1 == request2) {
        return YES;
    }
    if (![[request1.asset assetID] isEqualToString:[request2.asset assetID]]) {
        return NO;
    }
    return (CGSizeEqualToSize(request1.targetSize, request2.targetSize) &&
            request1.contentMode == request2.contentMode &&
            request1.options.networkAccessAllowed == request2.options.networkAccessAllowed);
}

- (NSOperation *)startOperationWithRequest:(DFImageRequest *)request completion:(void (^)(DFImageResponse *))completion {
    DFPhotosKitImageFetchOperation *operation =[[DFPhotosKitImageFetchOperation alloc] initWithRequest:request];
    DFPhotosKitImageFetchOperation *__weak weakOp = operation;
    [operation setCompletionBlock:^{
        completion(weakOp.response);
    }];
    [_queue addOperation:operation];
    return operation;
}

@end
