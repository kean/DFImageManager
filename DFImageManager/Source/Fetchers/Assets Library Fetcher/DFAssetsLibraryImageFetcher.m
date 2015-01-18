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

#import "DFAssetsLibraryImageFetchOperation.h"
#import "DFAssetsLibraryImageFetcher.h"
#import "DFAssetsLibraryUtilities.h"
#import "DFImageAssetProtocol.h"
#import "DFImageRequest.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <UIKit/UIKit.h>


@implementation DFAssetsLibraryImageFetcher {
    NSOperationQueue *_queue;
    BOOL _isIpad;
}

- (instancetype)init {
    if (self = [super init]) {
        _queue = [NSOperationQueue new];
        _queue.maxConcurrentOperationCount = 2;
        _isIpad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    }
    return self;
}

#pragma mark - <DFImageFetcher>

- (BOOL)canHandleRequest:(DFImageRequest *)request {
    id asset = request.asset;
    if ([asset isKindOfClass:[ALAsset class]]) {
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

- (BOOL)isRequestEquivalent:(DFImageRequest *)request1 toRequest:(DFImageRequest *)request2 {
    if (request1 == request2) {
        return YES;
    }
    if (![request1.asset.uniqueImageAssetIdentifier isEqualToString:request2.asset.uniqueImageAssetIdentifier]) {
        return NO;
    }
    DFALAssetImageSize imageSize1 = [self _assetImageSizeForRequest:request1];
    DFALAssetImageSize imageSize2 = [self _assetImageSizeForRequest:request2];
    return imageSize1 == imageSize2;
}

- (DFALAssetImageSize)_assetImageSizeForRequest:(DFImageRequest *)request {
    // TODO: Improve decision making here.
    CGFloat thumbnailSide = _isIpad ? 125.f : 75.f;
    thumbnailSide *= [UIScreen mainScreen].scale;
    thumbnailSide *= 1.2f;
    if (request.targetSize.width <= thumbnailSide &&
        request.targetSize.height <= thumbnailSide) {
        return DFALAssetImageSizeThumbnail;
    } else {
        return DFALAssetImageSizeFullscreen;
    }
}

- (NSOperation<DFImageManagerOperation> *)createOperationForRequest:(DFImageRequest *)request  {
    DFAssetsLibraryImageFetchOperation *operation;
    if ([request.asset isKindOfClass:[ALAsset class]]) {
        operation = [[DFAssetsLibraryImageFetchOperation alloc] initWithAsset:(ALAsset *)request.asset];
    } else {
        operation = [[DFAssetsLibraryImageFetchOperation alloc] initWithAssetURL:(NSURL *)request.asset];
    }
    operation.imageSize = [self _assetImageSizeForRequest:request];
    return operation;
}

- (void)enqueueOperation:(NSOperation<DFImageManagerOperation> *)operation {
    [_queue addOperation:operation];
}

@end
