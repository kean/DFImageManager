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

#import "DFALAsset.h"
#import "DFAssetsLibraryImageFetchOperation.h"
#import "DFAssetsLibraryImageFetcher.h"
#import "DFAssetsLibraryImageRequestOptions.h"
#import "DFAssetsLibraryUtilities.h"
#import "DFImageRequest.h"
#import "DFImageResponse.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <UIKit/UIKit.h>


static inline NSURL *_ALAssetURL(id resource) {
    if ([resource isKindOfClass:[DFALAsset class]]) {
        return [((DFALAsset *)resource) assetURL];
    } else {
        return (NSURL *)resource;
    }
}

@implementation DFAssetsLibraryImageFetcher {
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
    if ([asset isKindOfClass:[DFALAsset class]]) {
        return YES;
    }
    if ([asset isKindOfClass:[NSURL class]]) {
        NSURL *URL = asset;
        if ([URL.scheme isEqualToString:@"assets-library"]) {
            return YES;
        }
    }
    return NO;
}

- (DFImageRequest *)canonicalRequestForRequest:(DFImageRequest *)request {
    if (!request.options || ![request.options isKindOfClass:[DFAssetsLibraryImageRequestOptions class]]) {
        DFAssetsLibraryImageRequestOptions *options = [[DFAssetsLibraryImageRequestOptions alloc] initWithOptions:request.options];
        options.imageSize = request != nil ? [self _assetImageSizeForRequest:request] : DFALAssetImageSizeFullscreen;
        
        DFImageRequest *canonicalRequest = [request copy];
        canonicalRequest.options = options;
        return canonicalRequest;
    }
    return request;
}

- (BOOL)isRequestFetchEquivalent:(DFImageRequest *)request1 toRequest:(DFImageRequest *)request2 {
    return [self isRequestCacheEquivalent:request1 toRequest:request2];
}

- (BOOL)isRequestCacheEquivalent:(DFImageRequest *)request1 toRequest:(DFImageRequest *)request2 {
    if (request1 == request2) {
        return YES;
    }
    if (![_ALAssetURL(request1.resource) isEqual:_ALAssetURL(request2.resource)]) {
        return NO;
    }
    DFAssetsLibraryImageRequestOptions *options1 = (id)request1.options;
    DFAssetsLibraryImageRequestOptions *options2 = (id)request1.options;
    return (options1.imageSize == options2.imageSize &&
            options1.version == options2.version);
}

- (DFALAssetImageSize)_assetImageSizeForRequest:(DFImageRequest *)request {
    // TODO: Improve decision making here.
    CGFloat thumbnailSide = [UIScreen mainScreen].bounds.size.width / 4.0;
    thumbnailSide *= [UIScreen mainScreen].scale;
    thumbnailSide *= 1.2f;
    if (request.targetSize.width <= thumbnailSide &&
        request.targetSize.height <= thumbnailSide) {
        return DFALAssetImageSizeAspectRatioThumbnail;
    }
    
    CGFloat fullscreenSide = MAX([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    fullscreenSide *= [UIScreen mainScreen].scale;
    if (request.targetSize.width <= fullscreenSide &&
        request.targetSize.height <= fullscreenSide) {
        return DFALAssetImageSizeFullscreen;
    }

    return DFALAssetImageSizeFullsize;
}

- (NSOperation *)startOperationWithRequest:(DFImageRequest *)request progressHandler:(void (^)(double))progressHandler completion:(void (^)(DFImageResponse *))completion {
    DFAssetsLibraryImageFetchOperation *operation;
    if ([request.resource isKindOfClass:[DFALAsset class]]) {
        operation = [[DFAssetsLibraryImageFetchOperation alloc] initWithAsset:((DFALAsset *)request.resource).asset];
    } else {
        operation = [[DFAssetsLibraryImageFetchOperation alloc] initWithAssetURL:(NSURL *)request.resource];
    }
    DFAssetsLibraryImageRequestOptions *options = (id)request.options;
    operation.imageSize = options.imageSize;
    operation.version = options.version;
    
    DFAssetsLibraryImageFetchOperation *__weak weakOp = operation;
    [operation setCompletionBlock:^{
        DFMutableImageResponse *response = [DFMutableImageResponse new];
        response.image = weakOp.image;
        response.error = weakOp.error;
        completion(response);
    }];
    [_queue addOperation:operation];
    return operation;
}

@end
