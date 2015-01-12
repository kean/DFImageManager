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

#import "ALAssetsLibrary+DFImageManager.h"
#import "DFAssetsLibraryImageFetchOperation.h"
#import "DFImageResponse.h"
#import <AssetsLibrary/AssetsLibrary.h>


@implementation DFAssetsLibraryImageFetchOperation {
    ALAsset *_asset;
    NSURL *_assetURL;
    DFImageResponse *_response;
}

- (instancetype)init {
    if (self = [super init]) {
        _imageSize = DFALAssetImageSizeThumbnail;
    }
    return self;
}

- (instancetype)initWithAsset:(ALAsset *)asset {
    if (self = [self init]) {
        _asset = asset;
    }
    return self;
}

- (instancetype)initWithAssetURL:(NSURL *)assetURL {
    if (self = [self init]) {
        _assetURL = assetURL;
    }
    return self;
}

#pragma mark - Operation

- (void)start {
    [super start];
    
    if (self.isCancelled) {
        [self finish];
    } else {
        DFAssetsLibraryImageFetchOperation *__weak weakSelf = self;
        if (!_asset) {
            [[ALAssetsLibrary sharedLibrary] assetForURL:_assetURL resultBlock:^(ALAsset *asset) {
                [weakSelf _didReceiveAsset:asset];
            } failureBlock:^(NSError *error) {
                [weakSelf _didFailWithError:error];
            }];
        } else {
            [self _startFetching];
        }
    }
}

- (void)_startFetching {
    UIImage *image;
    
    switch (_imageSize) {
        case DFALAssetImageSizeThumbnail:
            image = [UIImage imageWithCGImage:_asset.aspectRatioThumbnail scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
            break;
        case DFALAssetImageSizeFullscreen: {
            ALAssetRepresentation *assetRepresentation = [_asset defaultRepresentation];
            image = [UIImage imageWithCGImage:[assetRepresentation fullScreenImage] scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
        }
            break;
        default:
            break;
    }
    
    _response = [[DFImageResponse alloc] initWithImage:image];
    [self finish];
}

- (void)_didReceiveAsset:(ALAsset *)asset {
    _asset = asset;
    if (self.isCancelled) {
        [self finish];
        return;
    }
    [self _startFetching];
}

- (void)_didFailWithError:(NSError *)error {
    _response = [[DFImageResponse alloc] initWithError:error];
    [self finish];
}

#pragma mark - <DFImageManagerOperation>

- (DFImageResponse *)imageResponse {
    return _response;
}

@end
