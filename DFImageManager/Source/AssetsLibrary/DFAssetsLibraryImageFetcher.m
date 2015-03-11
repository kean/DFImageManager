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
#import "DFAssetsLibraryDefines.h"
#import "DFAssetsLibraryImageFetchOperation.h"
#import "DFAssetsLibraryImageFetcher.h"
#import "DFImageRequest.h"
#import "DFImageRequestOptions.h"
#import "DFImageResponse.h"
#import <UIKit/UIKit.h>


NSString *const DFAssetsLibraryImageSizeKey = @"DFAssetsLibraryImageSizeKey";
NSString *const DFAssetsLibraryAssetVersionKey = @"DFAssetsLibraryAssetVersionKey";

typedef struct {
    DFALAssetImageSize imageSize;
    DFALAssetVersion version;
} _DFAssetsRequestOptions;

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
        _queue.maxConcurrentOperationCount = 3;
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
    _DFAssetsRequestOptions options1 = [self _assetRequestOptionsForRequest:request1];
    _DFAssetsRequestOptions options2 = [self _assetRequestOptionsForRequest:request2];
    return (options1.imageSize == options2.imageSize &&
            options1.version == options2.version);
}

- (_DFAssetsRequestOptions)_assetRequestOptionsForRequest:(DFImageRequest *)request {
    _DFAssetsRequestOptions options;
    NSDictionary *userInfo = request.options.userInfo;
    NSNumber *imageSize = userInfo[DFAssetsLibraryImageSizeKey];
    options.imageSize = imageSize ? [imageSize integerValue] : [self _assetImageSizeForRequest:request];
    NSNumber *version = userInfo[DFAssetsLibraryAssetVersionKey];
    options.version = version ? [version integerValue] : DFALAssetVersionCurrent;
    return options;
}

- (DFALAssetImageSize)_assetImageSizeForRequest:(DFImageRequest *)request {
    // TODO: Improve decision making here.
    CGFloat thumbnailSide = [UIScreen mainScreen].bounds.size.width / 4.f;
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
    _DFAssetsRequestOptions options = [self _assetRequestOptionsForRequest:request];
    operation.imageSize = options.imageSize;
    operation.version = options.version;
    
    DFAssetsLibraryImageFetchOperation *__weak weakOp = operation;
    [operation setCompletionBlock:^{
        if (completion) {
            completion([[DFImageResponse alloc] initWithImage:weakOp.image error:weakOp.error userInfo:nil]);
        }
    }];
    [_queue addOperation:operation];
    return operation;
}

@end
