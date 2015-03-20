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
#import <AssetsLibrary/AssetsLibrary.h>
#import <UIKit/UIKit.h>

@interface DFAssetsLibraryImageFetchOperation ()

@property (nonatomic, getter = isExecuting) BOOL executing;
@property (nonatomic, getter = isFinished) BOOL finished;

@end

@implementation DFAssetsLibraryImageFetchOperation {
    ALAsset *_asset;
    NSURL *_assetURL;
}

@synthesize executing = _executing;
@synthesize finished = _finished;

- (instancetype)init {
    if (self = [super init]) {
        _imageSize = DFALAssetImageSizeThumbnail;
        _version = DFALAssetVersionCurrent;
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

- (void)start {
    self.executing = YES;
    if (self.isCancelled) {
        [self finish];
    } else {
        DFAssetsLibraryImageFetchOperation *__weak weakSelf = self;
        if (!_asset) {
            [[ALAssetsLibrary df_sharedLibrary] assetForURL:_assetURL resultBlock:^(ALAsset *asset) {
                [weakSelf _didReceiveAsset:asset];
            } failureBlock:^(NSError *error) {
                [weakSelf _didFailWithError:error];
            }];
        } else {
            [self _startFetching];
        }
    }
}

- (void)finish {
    if (_executing) {
        self.executing = NO;
    }
    self.finished = YES;
}

- (void)_startFetching {
    if (_version == DFALAssetVersionCurrent) {
        switch (_imageSize) {
            case DFALAssetImageSizeAspectRatioThumbnail:
                _image = [UIImage imageWithCGImage:_asset.aspectRatioThumbnail scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
                break;
            case DFALAssetImageSizeThumbnail:
                _image = [UIImage imageWithCGImage:_asset.thumbnail scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
                break;
            case DFALAssetImageSizeFullscreen: {
                ALAssetRepresentation *assetRepresentation = [_asset defaultRepresentation];
                _image = [UIImage imageWithCGImage:[assetRepresentation fullScreenImage] scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
            }
                break;
            case DFALAssetImageSizeFullsize:
                _image = [self _fullResolutionAdjustedImage];
                break;
            default:
                break;
        }
    } else {
        _image = [self _fullResolutionUnadjustedImage];
    }
    [self finish];
}

- (UIImage *)_fullResolutionUnadjustedImage {
    ALAssetRepresentation *representation = [_asset defaultRepresentation];
    CGImageRef imageRef = [representation fullResolutionImage];
    UIImageOrientation orientation = (UIImageOrientation)representation.orientation;
    return [UIImage imageWithCGImage:imageRef scale:[representation scale] orientation:orientation];
}

- (UIImage *)_fullResolutionAdjustedImage {
    ALAssetRepresentation *representation = [_asset defaultRepresentation];
    
    // WARNING: This code doesn't work for iOS 8.0+. Use PhotosKit instead.
    CGImageRef imageRef = [representation fullResolutionImage];
    NSString *adjustment = [representation metadata][@"AdjustmentXMP"];
    if (adjustment != nil) {
        NSData *xmpData = [adjustment dataUsingEncoding:NSUTF8StringEncoding];
        CIImage *image = [CIImage imageWithCGImage:imageRef];
        
        NSError *error = nil;
        NSArray *filterArray = [CIFilter filterArrayFromSerializedXMP:xmpData inputImageExtent:image.extent error:&error];
        CIContext *context = [CIContext contextWithOptions:nil];
        if (filterArray != nil && !error) {
            for (CIFilter *filter in filterArray) {
                [filter setValue:image forKey:kCIInputImageKey];
                image = [filter outputImage];
            }
            // TODO: Fix crash when OpenGL calls are made in the background
            imageRef = [context createCGImage:image fromRect:[image extent]];
        }
    }
    UIImageOrientation orientation = (UIImageOrientation)representation.orientation;
    return [UIImage imageWithCGImage:imageRef scale:[representation scale] orientation:orientation];
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
    _error = error;
    [self finish];
}

- (void)setFinished:(BOOL)finished {
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)setExecuting:(BOOL)executing {
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

@end
