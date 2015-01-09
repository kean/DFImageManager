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
#import "DFAssetsLibraryImageManagerConfiguration.h"
#import "DFAssetsLibraryUtilities.h"
#import <AssetsLibrary/AssetsLibrary.h>


@implementation DFAssetsLibraryImageManagerConfiguration {
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

#pragma mark - <DFImageManagerConfiguration>

- (BOOL)imageManager:(id<DFImageManager>)manager canHandleRequest:(DFImageRequest *)request {
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

- (NSString *)imageManager:(id<DFImageManager>)manager uniqueIDForAsset:(id)asset {
    if ([asset isKindOfClass:[ALAsset class]]) {
        return [((ALAsset *)asset).defaultRepresentation.url absoluteString];
    } else if ([asset isKindOfClass:[NSURL class]]) {
        return [((NSURL *)asset) absoluteString];
    }
    return nil;
}

- (NSString *)imageManager:(id<DFImageManager>)manager executionContextIDForRequest:(DFImageRequest *)request {
    NSString *assetUID = [self imageManager:manager uniqueIDForAsset:request.asset];
    DFALAssetImageSize imageSize = [self _assetImageSizeForRequest:request];
    NSMutableString *ECID = [[NSMutableString alloc] initWithString:@"requestID?"];
    [ECID appendFormat:@"imageSize=%i", (int)imageSize];
    [ECID appendFormat:@"assetID=%@", assetUID];
    return assetUID;
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

- (NSOperation<DFImageManagerOperation> *)imageManager:(id<DFImageManager>)manager createOperationForRequest:(DFImageRequest *)request previousOperation:(NSOperation<DFImageManagerOperation> *)previousOperation {
    if (!previousOperation) {
        DFAssetsLibraryImageFetchOperation *operation;
        if ([request.asset isKindOfClass:[ALAsset class]]) {
            operation = [[DFAssetsLibraryImageFetchOperation alloc] initWithAsset:request.asset];
        } else {
            operation = [[DFAssetsLibraryImageFetchOperation alloc] initWithAssetURL:request.asset];
        }
        operation.imageSize = [self _assetImageSizeForRequest:request];
        return operation;
    }
    return nil;
}

- (void)imageManager:(id<DFImageManager>)manager enqueueOperation:(NSOperation<DFImageManagerOperation> *)operation {
    [_queue addOperation:operation];
}

@end
