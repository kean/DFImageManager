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
#import "DFPHAssetlocalIdentifier.h"
#import "DFPHImageFetchOperation.h"
#import <Photos/Photos.h>


@interface DFPHImageFetchOperation ()

@property (nonatomic, getter = isExecuting) BOOL executing;
@property (nonatomic, getter = isFinished) BOOL finished;

@end

@implementation DFPHImageFetchOperation {
    PHAsset *_asset;
    DFPHAssetlocalIdentifier *_assetLocalIdentifier;
    CGSize _targetSize;
    DFImageContentMode _contentMode;
    DFImageRequestOptions *_options;
    
    DFImageResponse *_response;
}

@synthesize executing = _executing;
@synthesize finished = _finished;

- (instancetype)initWithRequest:(DFImageRequest *)request {
    if (self = [super init]) {
        if ([request.asset isKindOfClass:[PHAsset class]]) {
            _asset = request.asset;
        } else {
            _assetLocalIdentifier = request.asset;
        }
        _targetSize = request.targetSize;
        _contentMode = request.contentMode;
        _options = request.options;
    }
    return self;
}

- (void)start {
    @synchronized(self) {
        if ([self isCancelled]) {
            [self finish];
            return;
        }
        self.executing = YES;
    }
    
    if (!_asset) {
        _asset = [[PHAsset fetchAssetsWithLocalIdentifiers:@[_assetLocalIdentifier.identifier] options:nil] firstObject];
    }
    
    PHImageRequestOptions *options = [PHImageRequestOptions new];
    options.networkAccessAllowed = _options.networkAccessAllowed;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    options.resizeMode = PHImageRequestOptionsResizeModeFast;
    
    PHImageContentMode contentMode = [self _PHContentModeForDFContentMode:_contentMode];
    
    DFPHImageFetchOperation *__weak weakSelf = self;
    [[PHImageManager defaultManager] requestImageForAsset:_asset targetSize:_targetSize contentMode:contentMode options:options resultHandler:^(UIImage *result, NSDictionary *info) {
        result = result ? [UIImage imageWithCGImage:result.CGImage scale:[UIScreen mainScreen].scale orientation:result.imageOrientation] : nil;
        [weakSelf _didFetchImage:result];
    }];
}

- (PHImageContentMode)_PHContentModeForDFContentMode:(DFImageContentMode)contentMode {
    switch (contentMode) {
        case DFImageContentModeAspectFill: return PHImageContentModeAspectFill;
        case DFImageContentModeAspectFit: return PHImageContentModeAspectFit;
        default: return PHImageContentModeDefault;
    }
}

- (void)_didFetchImage:(UIImage *)result {
    DFMutableImageResponse *response = [DFMutableImageResponse new];
    response.image = result;
    _response = [response copy];
    [self finish];
}

#pragma mark - Operation

- (void)finish {
    @synchronized(self) {
        if (_executing) {
            self.executing = NO;
        }
        self.finished = YES;
    }
}

#pragma mark - <DFImageManagerOperation>

- (DFImageResponse *)imageResponse {
    return _response;
}

#pragma mark - KVO

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
