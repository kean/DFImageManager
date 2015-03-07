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
#import "DFImageResponse.h"
#import "DFPhotosKitImageFetchOperation.h"
#import "DFPhotosKitImageRequestOptions.h"
#import "NSURL+DFPhotosKit.h"
#import <Photos/Photos.h>


@implementation DFPhotosKitImageFetchOperation {
    PHAsset *_asset;
    NSURL *_assetURL;
    CGSize _targetSize;
    DFImageContentMode _contentMode;
    DFPhotosKitImageRequestOptions *_options;
    PHImageRequestID _requestID;
}

- (instancetype)initWithRequest:(DFImageRequest *)request {
    if (self = [super init]) {
        if ([request.resource isKindOfClass:[PHAsset class]]) {
            _asset = (PHAsset *)request.resource;
        } else if ([request.resource isKindOfClass:[NSURL class]]) {
            _assetURL = (NSURL *)request.resource;
        }
        _targetSize = request.targetSize;
        _contentMode = request.contentMode;
        _options = (DFPhotosKitImageRequestOptions *)request.options;
        NSParameterAssert([request.options isKindOfClass:[DFPhotosKitImageRequestOptions class]]);
        _requestID = PHInvalidImageRequestID;
    }
    return self;
}

- (void)start {
    @synchronized(self) {
        [super start];
        if (self.isCancelled) {
            [self finish];
        } else {
            [self _fetch];
        }
    }
}

- (void)_fetch {
    if (!_asset && _assetURL != nil) {
        NSString *localIdentifier = [_assetURL df_assetLocalIdentifier];
        if (localIdentifier != nil) {
            _asset = [[PHAsset fetchAssetsWithLocalIdentifiers:@[localIdentifier] options:nil] firstObject];
        }
    }
    
    if (self.isCancelled) {
        [self finish];
        return;
    }
    
    PHImageRequestOptions *options = [PHImageRequestOptions new];
    options.networkAccessAllowed = _options.allowsNetworkAccess;
    options.deliveryMode = _options.deliveryMode;
    if (options.deliveryMode == PHImageRequestOptionsDeliveryModeOpportunistic) {
        NSLog(@"%@: PHImageRequestOptionsDeliveryModeOpportunistic is unsupported", self);
        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    }
    options.resizeMode = _options.resizeMode;
    options.version = _options.version;
    
    PHImageContentMode contentMode = [self _PHContentModeForDFContentMode:_contentMode];
    
    DFPhotosKitImageFetchOperation *__weak weakSelf = self;
    _requestID = [[PHImageManager defaultManager] requestImageForAsset:_asset targetSize:_targetSize contentMode:contentMode options:options resultHandler:^(UIImage *result, NSDictionary *info) {
        result = result ? [UIImage imageWithCGImage:result.CGImage scale:[UIScreen mainScreen].scale orientation:result.imageOrientation] : nil;
        [weakSelf _didFetchImage:result info:info];
    }];
}

- (PHImageContentMode)_PHContentModeForDFContentMode:(DFImageContentMode)contentMode {
    switch (contentMode) {
        case DFImageContentModeAspectFill: return PHImageContentModeAspectFill;
        case DFImageContentModeAspectFit: return PHImageContentModeAspectFit;
        default: return PHImageContentModeDefault;
    }
}

- (void)_didFetchImage:(UIImage *)result info:(NSDictionary *)info {
    @synchronized(self) {
        if (!self.isCancelled) {
            DFMutableImageResponse *response = [DFMutableImageResponse new];
            response.image = result;
            response.userInfo = info;
            _response = [response copy];
            [self finish];
        }
    }
}

- (void)cancel {
    @synchronized(self) {
        if (!self.isCancelled && !self.isFinished) {
            [super cancel];
            if (_requestID != PHInvalidImageRequestID) {
                /*! From Apple docs: "If the request is cancelled, resultHandler may not be called at all.", that's why all the mess.
                 */
                [[PHImageManager defaultManager] cancelImageRequest:_requestID];
                [self finish];
            }
        }
    }
}

@end
